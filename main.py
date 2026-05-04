import requests
import os
import json
import re
from urllib.parse import urlencode

ENDPOINTS = {
    "game": "https://launcher.gryphline.com/api/game/get_latest",
    "launcher": "https://launcher.gryphline.com/api/launcher/get_latest",
    "resource": "https://launcher.gryphline.com/api/game/get_latest_resources"
}

CONFIG = {
    "live": {
        "params": {
            "common": {
                "appcode": "YDUTE5gscDZ229CW",
                "channel": "6",
                "launcher_appcode": "TiaytKBUIEdoEwRT",
                "launcher_sub_channel": "6",
                "sub_channel": "6"
            },
            "launcher": {
                "appcode": "TiaytKBUIEdoEwRT",
                "channel": "6",
                "sub_channel": "6",
                "target_app": "EndField"
            }
        }
    },
    "beta": {
        "params": {
            "common": {},
            "launcher": {}
        }
    }
}

def build_url(url, params):
    if not url:
        return ""
    sorted_params = dict(sorted(params.items()))
    query_string = urlencode(sorted_params)
    return f"{url}?{query_string}"

def get_config_version(url):
    if not url:
        return None, None
    try:
        response = requests.get(url)
        response.raise_for_status()
        data = response.json()
        
        version = data.get("version")
        return version, data
    except Exception as e:
        print(f"Error parsing {url}: {e}")
        return None, None

def save_file(directory, filename, content):
    if not os.path.exists(directory):
        os.makedirs(directory)
    with open(os.path.join(directory, filename), 'wb') as f:
        f.write(content)

def process_game(env, config):
    game_endpoint = ENDPOINTS["game"]
    common_params = config["params"]["common"]
    
    if not game_endpoint or not common_params:
        return

    url = build_url(game_endpoint, common_params)
    
    version, data = get_config_version(url)
    if version:
        base_name = url.split('?')[0].split('/')[-1]
        filename = f"{base_name}.json"
        game_directory = f"{env}/game/{version}"
        
        content = json.dumps(data, indent=4, ensure_ascii=False).encode('utf-8')
        save_file(game_directory, filename, content)
        print(f"Saved {filename} to {game_directory}")

        pkg = data.get("pkg", {})
        file_path = pkg.get("file_path", "")
        
        rand_str_match = re.search(r'_([^/]+)/.+?$', file_path)
        rand_str = rand_str_match.group(1) if rand_str_match else None
        
        if rand_str:
            game_version = ".".join(version.split(".")[:2])
            
            appcode = common_params.get("appcode", "")
            
            resource_params = {
                "appcode": appcode,
                "game_version": game_version,
                "platform": "Windows",
                "rand_str": rand_str,
                "version": version
            }
            
            resource_endpoint = ENDPOINTS["resource"]
            
            full_resource_url = build_url(resource_endpoint, resource_params)
            
            try:
                res_resp = requests.get(full_resource_url)
                res_resp.raise_for_status()
                res_data = res_resp.json()
                
                res_version = "unknown"
                resources_list = res_data.get("resources", [])
                for res in resources_list:
                    if res.get("name") == "main":
                        res_version = res.get("version")
                        break
                
                if res_version == "unknown":
                    print("Warning: Could not find 'main' resource version, using default.")

                res_content = json.dumps(res_data, indent=4, ensure_ascii=False).encode('utf-8')
                res_filename = "get_latest_resources.json"
                
                resource_directory = f"{env}/resources/{version}/{res_version}"
                
                save_file(resource_directory, res_filename, res_content)
                print(f"Saved {res_filename} to {resource_directory}")
                
            except Exception as e:
                print(f"Error fetching resources: {e}")
        else:
            print(f"Could not extract rand_str from file_path: {file_path}")
    else:
        print(f"Game version not found or error for {env}")

def process_launcher(env, config):
    launcher_endpoint = ENDPOINTS["launcher"]
    launcher_params = config["params"]["launcher"]
    
    if not launcher_endpoint or not launcher_params:
        return

    url = build_url(launcher_endpoint, launcher_params)

    version, data = get_config_version(url)
    if version:
        base_name = url.split('?')[0].split('/')[-1]
        filename = f"{base_name}.json"
        directory = f"{env}/launcher/{version}"
        
        content = json.dumps(data, indent=4, ensure_ascii=False).encode('utf-8')
        save_file(directory, filename, content)
        print(f"Saved {filename} to {directory}")
    else:
        print(f"Launcher version not found or error for {env}")

def process_urls():
    for env, config in CONFIG.items():
        process_game(env, config)
        process_launcher(env, config)

if __name__ == "__main__":
    process_urls()

