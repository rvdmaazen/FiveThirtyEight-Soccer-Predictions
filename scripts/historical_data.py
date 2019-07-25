import requests
import pandas as pd
import os
from dateutil.parser import parse


def get_historical_data(competition, year):
    season = f"{year}-{year + 1}"
    print(f"Fetching historical data for {competition} ({season})")
    response = requests.get(
        f"https://projects.fivethirtyeight.com/soccer-predictions/forecasts/{year}_{competition}_forecast.json"
    )

    if response.status_code != 404:
        json_data = response.json()

        table_df = pd.DataFrame()
        for date in json_data["forecasts"]:
            table_data = []
            last_updated = list(date.values())[0]
            last_updated = parse(last_updated)
            last_updated = last_updated.strftime("%Y-%m-%d %H:%M")
            teams = date["teams"]
            headers = list(teams[0].keys())
            headers.append("last_updated")

            for team in teams:
                row_data = list(team.values())
                row_data.append(last_updated)
                table_data.append(row_data)

            df = pd.DataFrame(data=table_data, columns=headers)
            table_df = pd.concat(
                [table_df, df], axis=0, ignore_index=True, sort=False
            )

        # Create folder if it doesn't exist
        filename = "data/{}/{}.csv".format(season, competition)
        os.makedirs(os.path.dirname(filename), exist_ok=True)
        table_df.to_csv(filename, index=False)


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

    for year in [2016, 2017, 2018]:
        for competition in competitions:
            get_historical_data(competition, year)
