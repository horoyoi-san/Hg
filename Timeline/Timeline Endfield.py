from timeline_utils import bangkok_datetime, run_timeline


CONFIG = {
    "game_name": "Arknights: Endfield",
    "start_dates": {
        "Drip": bangkok_datetime(2026, 7, 10, 18, 0),
        "BETA": bangkok_datetime(2026, 7, 10, 10, 0),
        "Live": bangkok_datetime(2026, 8, 21, 19, 30),
        "Predownload": bangkok_datetime(2026, 9, 1, 13, 0),
        "Release": bangkok_datetime(2026, 9, 3, 10, 0),
    },
    "intervals": {
        "Drip": 42,
        "BETA": 42,
        "Live": 42,
        "Predownload": 42,
        "Release": 42,
    },
    "phase_labels": {
        "Drip": "Drip",
        "BETA": "BETA",
        "Live": "Live",
        "Predownload": "Predownload",
        "Release": "Release",
    },
    "start_version": 1.5,
    "end_version": 8.0,
    "output_file": "data/Endfield.txt",
    "bullet": True,
}


if __name__ == "__main__":
    run_timeline(CONFIG)