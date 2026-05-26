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

POLISH_MONTHS = {
    1: "stycznia",
    2: "lutego",
    3: "marca",
    4: "kwietnia",
    5: "maja",
    6: "czerwca",
    7: "lipca",
    8: "sierpnia",
    9: "wrzesieńia",
    10: "października",
    11: "listopada",
    12: "grudnia"
}



def get_polish_day_of_week(date_text: str):
    try:
        date_object = datetime.strptime(date_text, "%Y-%m-%d")
        weekday_number = date_object.weekday()

        return POLISH_WEEKDAYS[weekday_number]
    
    except ValueError:
        return ""
    
def get_polish_formatted_date(date_text: str):
    try:
        date_object = datetime.strptime(date_text, "%Y-%m-%d")

        weekday_number = date_object.weekday()
        day_of_week = POLISH_WEEKDAYS[weekday_number]

        day = date_object.day
        month = POLISH_MONTHS[date_object.month]
        year = date_object.year

        return f"{day_of_week}, {day} {month} {year}"
    
    except ValueError:
        return date_text
