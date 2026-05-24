from datetime import datetime

POLISH_WEEKDAYS = {
    0: "Poniedziałek",
    1: "Wtorek",
    2: "Środa",
    3: "Czwartek",
    4: "Piątek",
    5: "Sobota",
    6: "Niedziela"
}

def get_polish_day_of_week(date_text: str):
    try:
        date_object = datetime.strptime(date_text, "%Y-%m-%d")
        weekday_number = date_object.weekday()

        return POLISH_WEEKDAYS[weekday_number]
    
    except ValueError:
        return ""