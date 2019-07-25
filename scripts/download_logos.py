import requests
from bs4 import BeautifulSoup
import pandas as pd
import os


def get_links(competitions):
    team_logos = pd.DataFrame(columns=["Team", "Logo link", "Competition"])

    for competition in competitions:
        print(f"Fetching data for {competition}")
        base_url = "https://projects.fivethirtyeight.com/soccer-predictions/"
        url = base_url + competition
        page = requests.get(url)
        soup = BeautifulSoup(page.text, "html.parser")

        table_body = soup.find_all("tr", {"class": "team-row"})

        logo_links = [x.find("img")["src"] for x in table_body]
        logo_links = [x.replace("&w=56", "&w=512") for x in logo_links]
        team_names = [
            x.find("div", {"class", "name"}).contents[0] for x in table_body
        ]

        df = pd.DataFrame({"Team": team_names, "Logo link": logo_links})
        df["Competition"] = competition
        team_logos = team_logos.append(df, ignore_index=True)
        print(f"Finished fetching data for {competition}")

    return team_logos


def download_team_logos(lst):
    default_img_url = "https://secure.espn.com/combiner/i?img=/i/teamlogos/soccer/500/default-team-logo-500.png&amp;w=512"
    image_url = lst[1]
    img_data = requests.get(image_url).content
    if b"error" in img_data:
        img_data = requests.get(default_img_url).content
    filename = f"logos/{lst[2]}/{lst[0]}.png"
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, "wb") as f:
        f.write(img_data)


def download_comp_logos(competitions):
    for competition in competitions:
        image_url = f"https://projects.fivethirtyeight.com/soccer-predictions/images/{competition}-logo.png"
        img_data = requests.get(image_url).content
        filename = "logos/competitions/{}.png".format(competition)
        os.makedirs(os.path.dirname(filename), exist_ok=True)
        with open(filename, "wb") as f:
            f.write(img_data)


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

    # Read in logo data and convert to matrix
    logo_data = get_links(competitions)
    logo_data = logo_data.values

    for row in logo_data:
        print(f"Downloading logo for {row[0]} ({row[2]})")
        download_team_logos(row)

    download_comp_logos(competitions)
