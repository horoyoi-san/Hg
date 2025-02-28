// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use futures_util::stream::StreamExt;
use reqwest::{header, Client};
use std::fs;
use std::sync::{Arc, atomic::{AtomicUsize, Ordering}};
use sha2::{Digest, Sha256};
use serde_json::Value;
use std::os::windows::process::CommandExt;
use std::{fs::File, io::{BufRead, BufReader, Read}, path::{Path, PathBuf}};
use std::process::{Command, Stdio};
use std::thread;
use tauri::{Emitter, Window};
use tokio::fs::OpenOptions;
use tokio::io::AsyncWriteExt;
use tokio::task;
use tokio::time::{Duration, Instant};
use std::sync::Mutex;
use rayon::prelude::*;

#[tauri::command]
async fn check_integrity(
    window: Window,
    game_dir: String,
    manifest_path: String,
) -> Result<Vec<String>, String> {
    let manifest_content = std::fs::read_to_string(&manifest_path)
        .map_err(|e| format!("Error while reading manifest: {}", e))?;
    let manifest: Value = serde_json::from_str(&manifest_content)
        .map_err(|e| format!("Error while parsing manifest: {}", e))?;
    
    let files_map = manifest["files"]
        .as_object()
        .ok_or("Uncorrect manifest format")?;

    let files: Vec<_> = files_map.iter().collect();
    let total_files = files.len();
    
    let checked_files = Arc::new(AtomicUsize::new(0));
    let missing_files = Arc::new(Mutex::new(Vec::new()));

    files.par_iter().for_each(|(file, file_data)| {
        let expected_hash = file_data["hash"].as_str().unwrap_or("");
        let file_path = Path::new(&game_dir).join(file);
        
        let is_missing = if !file_path.exists() {
            true
        } else {
            match hash_file(&file_path) {
                Ok(actual_hash) => actual_hash != expected_hash,
                Err(_) => true,
            }
        };

        if is_missing {
            let mut missing = missing_files.lock().unwrap();
            missing.push(file.to_string());
        }

        let checked = checked_files.fetch_add(1, Ordering::SeqCst) + 1;
        let progress = (checked as f64 / total_files as f64) * 100.0;
        let _ = window.emit("integrity_progress", (progress, checked, total_files));
    });

    let missing_files = Arc::try_unwrap(missing_files).unwrap().into_inner().unwrap();
    let _ = window.emit("integrity_progress", "Checking complete!").unwrap();
    Ok(missing_files)
}

fn hash_file(path: &Path) -> Result<String, std::io::Error> {
    let file = File::open(path)?;
    let mut reader = BufReader::new(file);
    let mut hasher = Sha256::new();
    let mut buffer = [0; 8192];

    while let Ok(n) = reader.read(&mut buffer) {
        if n == 0 { break; }
        hasher.update(&buffer[..n]);
    }

    Ok(format!("{:x}", hasher.finalize()))
}

#[tauri::command]
async fn download_file(
    url: String,
    resource_path: String,
    window: tauri::Window,
) -> Result<(), String> {
    let filename = url.split('/').last().ok_or("Invalid URL")?;
    let temp_dir = format!("{}/temp", resource_path);
    let file_path = format!("{}/{}", temp_dir, filename);

    if !Path::new(&temp_dir).exists() {
        fs::create_dir_all(&temp_dir).map_err(|e| e.to_string())?;
    }

    let client = Client::new();
    let downloaded_size = if Path::new(&file_path).exists() {
        fs::metadata(&file_path).map(|meta| meta.len()).unwrap_or(0)
    } else {
        0
    };

    println!(
        "Resuming download: {} -> {} ({} bytes downloaded)",
        url, file_path, downloaded_size
    );

    let mut request = client.get(&url).header("User-Agent", "Mozilla/5.0");
    if downloaded_size > 0 {
        request = request.header(header::RANGE, format!("bytes={}-", downloaded_size));
    }

    let response = request.send().await.map_err(|e| e.to_string())?;
    let total_size = response.content_length().unwrap_or(0) + downloaded_size;
    println!("Total file size: {} bytes", total_size);
    let mut file = OpenOptions::new()
        .append(true)
        .create(true)
        .open(&file_path)
        .await
        .map_err(|e| e.to_string())?;

    let mut stream = response.bytes_stream();
    let mut downloaded = downloaded_size;
    let mut last_update = Instant::now();
    let mut last_downloaded = downloaded_size;

    while let Some(chunk) = stream.next().await {
        let chunk = chunk.map_err(|e| e.to_string())?;
        file.write_all(&chunk).await.map_err(|e| e.to_string())?;
        downloaded += chunk.len() as u64;

        if last_update.elapsed() >= Duration::from_secs(1) {
            let speed = (downloaded - last_downloaded) / 1024; // KB/s
            last_downloaded = downloaded;
            last_update = Instant::now();

            let progress = if total_size > 0 {
                (downloaded as f64 / total_size as f64) * 100.0
            } else {
                0.0
            };

            window
                .emit("download_progress", (progress, speed, total_size))
                .unwrap();
        }
    }

    println!("Download complete: {}", file_path);
    Ok(())
}

#[tauri::command]
async fn extract_archive(
    archive_path: String,
    extract_path: String,
    seven_zip_path: String,
    manifest_path: Option<String>,
    window: Window,
) -> Result<(), String> {
    let archive_path_clone = archive_path.clone();
    let extract_path_clone = extract_path.clone();

    task::spawn_blocking(move || {
        let extract_dir = Path::new(&extract_path_clone);
        if !extract_dir.exists() {
            fs::create_dir_all(&extract_dir).map_err(|e| e.to_string()).unwrap();
        }

        window.emit("extract_progress", "Extracting data, please wait...").unwrap();

        let list_output = Command::new(&seven_zip_path)
            .arg("l")
            .arg(&archive_path)
            .creation_flags(0x08000000)
            .output();

        let total_files = match list_output {
            Ok(output) if output.status.success() => {
                let output_str = String::from_utf8_lossy(&output.stdout);
                output_str
                    .lines()
                    .filter(|line| line.contains(" D.") || line.contains(" A."))
                    .count() as u64
            }
            _ => 0,
        };

        let copied_files = Arc::new(AtomicUsize::new(0));

        let output = Command::new(&seven_zip_path)
            .arg("x")
            .arg(&archive_path)
            .arg("-o".to_string() + &extract_path_clone)
            .arg("-y")
            .stdout(Stdio::piped())
            .creation_flags(0x08000000)
            .spawn();

        if let Ok(mut child) = output {
            let stdout = child.stdout.take().unwrap();
            let reader = BufReader::new(stdout);

            for line in reader.lines() {
                if let Ok(line) = line {
                    if line.starts_with("Extracting") {
                        let copied = copied_files.fetch_add(1, Ordering::SeqCst) + 1;
                        let progress = if total_files > 0 {
                            (copied as f64 / total_files as f64) * 100.0
                        } else {
                            0.0
                        };

                        window.emit("extract_progress", (progress, copied, total_files)).unwrap();
                    }
                }
            }

            let _ = child.wait();
        }

        if let Some(manifest_path) = manifest_path {
            eprintln!("Found manifest");
            if let Ok(manifest_content) = fs::read_to_string(&manifest_path) {
                if let Ok(manifest) = serde_json::from_str::<Value>(&manifest_content) {
                    if let Some(files) = manifest["files"].as_object() {
                        for (relative_path, _) in files.iter() {
                            let src = Path::new(&extract_path_clone).join(
                                Path::new(relative_path).file_name().unwrap(),
                            );

                            let dest = Path::new(&extract_path_clone).join(relative_path);

                            if let Some(parent) = dest.parent() {
                                fs::create_dir_all(parent).unwrap();
                            }

                            if src.exists() {
                                fs::rename(&src, &dest).unwrap_or_else(|_| {
                                    eprintln!("Err: {:?} -> {:?}", src, dest);
                                });
                            }
                        }
                    }
                }
            }
        }

        // Удаляем архив после распаковки
        if let Err(e) = fs::remove_file(&archive_path_clone) {
            eprintln!("Ошибка при удалении архива {}: {}", archive_path_clone, e);
        } else {
            window.emit("extract_progress", "Archive deleted successfully!").unwrap();
        }

        window.emit("extract_progress", "Extraction complete!").unwrap();
    })
    .await
    .map_err(|e| e.to_string())?;

    Ok(())
}

fn is_game_running() -> bool {
    let output = Command::new("tasklist")
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .creation_flags(0x08000000)
        .output()
        .expect("Failed to check running processes");

    let output_str = String::from_utf8_lossy(&output.stdout);
    output_str.contains("Endfield_TBeta_OS.exe")
}

#[tauri::command]
fn run_game(game_path: String, app_handle: tauri::AppHandle) -> Result<(), String> {
    let exe_path = PathBuf::from(game_path);

    if exe_path.exists() {
        let exe_str = exe_path.to_str().unwrap();
        let formatted_path = format!("'{}'", exe_str.replace("'", "''"));

        Command::new("powershell")
            .args([
                "-WindowStyle",
                "Hidden",
                "-Command",
                "Start-Process",
                formatted_path.as_str(),
                "-Verb",
                "RunAs",
            ])
            .creation_flags(0x08000000)
            .spawn()
            .map_err(|e| format!("Failed to launch game: {}", e))?;

        app_handle.emit("game_started", true).unwrap();
        thread::spawn(move || loop {
            thread::sleep(Duration::from_secs(5));
            if !is_game_running() {
                app_handle.emit("game_started", false).unwrap();
                break;
            }
        });

        Ok(())
    } else {
        Err("Game executable not found".to_string())
    }
}

fn main() {
    tauri::Builder::default()
        .plugin(tauri_plugin_dialog::init())
        .plugin(tauri_plugin_updater::Builder::new().build())
        .plugin(tauri_plugin_http::init())
        .plugin(tauri_plugin_opener::init())
        .plugin(tauri_plugin_fs::init())
        .plugin(tauri_plugin_store::Builder::new().build())
        .plugin(tauri_plugin_notification::init())
        .invoke_handler(tauri::generate_handler![
            run_game,
            download_file,
            extract_archive,
            check_integrity
        ])
        .run(tauri::generate_context!())
        .expect("Err");
}
