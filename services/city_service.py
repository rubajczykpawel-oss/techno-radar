CITY_TRANSLATIONS = {
    "Warsaw": "Warszawa",
    "Krakow": "Kraków",
    "Cracow": "Kraków",
    "Wroclaw": "Wrocław",
    "Gdansk": "Gdańsk",
    "Poznan": "Poznań",
    "Lodz": "Łódź",
    "Chorzow": "Chorzów",
    "Katowice": "Katowice",
    "Sopot": "Sopot",
    "Gdynia": "Gdynia",
    "Torun": "Toruń",
    "Szczecin": "Szczecin",
    "Lublin": "Lublin",
    "Bialystok": "Białystok",
    "Bydgoszcz": "Bydgoszcz",
    "Rzeszow": "Rzeszów"
}

def get_polish_city_name(city: str):
    if not city:
        return ""
    
    cleaned_city = city.strip()

    return CITY_TRANSLATIONS.get(cleaned_city, cleaned_city)