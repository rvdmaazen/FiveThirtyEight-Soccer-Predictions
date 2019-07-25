import requests
import pandas as pd
import os


def get_data(competition):
    print(f"Fetching data for {competition}...")

    path = f"data/2018-2019/{competition}.csv"

    url = f"https://projects.fivethirtyeight.com/soccer-predictions/forecasts/2018_{competition}_forecast.json"
    response = requests.get(url)
    json_data = response.json()

    table_data = []
    for team in json_data["forecasts"][0]["teams"]:
        row_data = list(team.values())
        table_data.append(row_data)

    headers = list(json_data["forecasts"][0]["teams"][0].keys())
    data = pd.DataFrame(data=table_data, columns=headers)
    data["current_time"] = pd.to_datetime("now")
    data["last_updated"] = pd.to_datetime(
        json_data["forecasts"][0]["last_updated"], infer_datetime_format=True
    )
    data["current_time"] = data["current_time"].dt.strftime("%Y-%m-%d %H:%M")
    data["last_updated"] = data["last_updated"].dt.strftime("%Y-%m-%d %H:%M")

    # Create folders if they don't exist yet
    os.makedirs(os.path.dirname(path), exist_ok=True)

    if not os.path.exists(path):
        data.to_csv(path, index=False)
    else:
        data.to_csv(path, index=False, mode="a", header=False)

    print(f"Finished fetching data for {competition}")


if __name__ == "__main__":
    competitions = [
        "champions-league",
        "europa-league",
        "bundesliga-austria",
        "first-division-a",
        "superligaen",
        "premier-league",
        "championship",
        "league-one",
        "league-two",
        "ligue-1",
        "ligue-2",
        "bundesliga",
        "bundesliga-2",
        "super-league-greece",
        "serie-a",
        "serie-b",
        "eredivisie",
        "eliteserien",
        "primeira-liga",
        "premier-league-russia",
        "premiership",
        "la-liga",
        "la-liga-2",
        "allsvenskan",
        "super-league",
        "super-lig",
    ]

    for competition in competitions:
        get_data(competition)
