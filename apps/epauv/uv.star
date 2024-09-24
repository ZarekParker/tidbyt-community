"""
Applet: UV
Summary: UV index
Description: UV index for your location.
Author: j-esse
"""

load("encoding/json.star", "json")
load("http.star", "http")
load("math.star", "math")
load("render.star", "render")
load("schema.star", "schema")
load("time.star", "time")
load("humanize.star", "humanize")

EPAUV_URL = "https://data.epa.gov/efservice/getEnvirofactsUVHOURLY/ZIP/80501/JSON"

OPENUV_REFRESH_RATE = 60 * 60  # 60 minutes in seconds
OPENUV_URL = "https://api.openuv.io/api/v1/uv"

OPENWEATHER_REFRESH_RATE = 60 * 60  # 60 minutes in seconds
OPENWEATHERMAP_URL = "https://api.openweathermap.org/data/3.0/onecall"

EPA_UV_REFRESH_RATE = 60 * 60 # 60 minutes in seconds

DEMO_DATA = 3, 11  # what to render when the app isn''t configured

uv_colors = [
    "#299501",
    "#299501",
    "#299501",
    "#f7e401",
    "#f7e401",
    "#f7e401",
    "#f95901",
    "#f95901",
    "#d90011",
    "#d90011",
    "#d90011",
    "#6c49cb",
]

def main(config):
    current_uv, max_uv = None, None
    # get_epa_uv(config)

    # if config.get("api_key") == None and config.get("location") == None:
    #     # demo mode
    #     current_uv, max_uv = DEMO_DATA

    # else:
    #     if config.get("api_key") == None or config.get("api_key") == "":
    #         return render.Root(render.WrappedText("Fix config:\nMissing\nAPI key"))
    #     if config.get("location") == None:
    #         return render.Root(render.WrappedText("Fix config:\nMissing\nlocation"))

    #     service = config.get("service", "openweather")

    current_uv, max_uv = get_epa_uv(config)
        # if service == "openweather":
        #     current_uv, max_uv = get_openweather_uv(config)

        #     if current_uv == None and max_uv == None:
        #         return render.Root(render.WrappedText("OpenWeather needs OneCall subscription"))

        # elif service == "openuv":
        #     current_uv, max_uv = get_openuv_uv(config)

    if current_uv == None or max_uv == None:
            return []

    columns = [
        render_uv_circle_column("UV", current_uv),
    ]

    if math.round(current_uv) != math.round(max_uv):
        columns.append(render_uv_circle_column("Later", max_uv))

    return render.Root(
        child = render.Row(
            expanded = True,
            main_align = "space_evenly",
            cross_align = "center",
            children = columns,
        ),
    )

def render_uv_circle_column(title, uv_index):
    return render.Column(
        expanded = True,
        main_align = "space_evenly",
        cross_align = "center",
        children = [
            render.Text(title),
            render_uv_circle(uv_index),
        ],
    )

def render_uv_circle(uv_index):
    uv_index_int = math.floor(math.round(uv_index))

    uv_color = uv_colors[11]
    if uv_index < 11:
        uv_color = uv_colors[uv_index_int]

    return render.Circle(
        color = uv_color,
        diameter = 22,
        child = render.Text(
            str(uv_index_int),
            color = "#000000",
            font = "10x20",
        ),
    )

def get_epa_uv(config):
    epa_uv_data = get_epa_uv_data(config)

    if epa_uv_data == None:
        return None, None

    # timezone = json.decode(config.get("location"))["timezone"]
    now = time.now() #.in_location(timezone)
    # print("time zone now is ", now)
    # print("time now is ", time.now())
    months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN", "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"]
    # zero_padded_hour = now.format("03:04")[:2]
    # print("zero", now.format("3:04am"))
    now_hour = humanize.time_format("KK aa", now)
    # if now.hour > 12:
        # now_hour = "%s PM" % (zero_padded_hour)
    # else:
        # now_hour = "%s AM" % (zero_padded_hour)
    # print("%s clean" % now_hour)
    
    # now_formatted = "%s/%d/%d %s" % (months[now.month-1], now.day, now.year, now_hour)
    now_formatted = "%s/%d/%d %s" % (months[now.month-1], 24, now.year, now_hour)
    
    # print("Now is formatted as %s" % ( epa_formatted))
    # print(epa_uv_data)
    
    max_uv = 0
    current_uv = None
    for uv_item in epa_uv_data:
        # print(float(uv_item.get("UV_VALUE")))
        # print(float(uv_item.get("UV_VALUE")) > max_uv)
        uv_item_date_time =  str(uv_item.get("DATE_TIME").upper())

        # get the max UV only for today
        if float(uv_item.get("UV_VALUE")) > max_uv and uv_item_date_time[:6] == now_formatted[:6]:
            max_uv = uv_item.get("UV_VALUE")
        # print(epa_formatted)
        # print('wat')
        # print(uv_item.get("DATE_TIME").upper())
        
        # print(str(uv_item.get("DATE_TIME".upper()) == str(epa_formatted.upper())))
        # print("wat", "%s" % tonight[:2] , "%s"% epa_formatted.upper()[:2])
        # print()
        if(uv_item_date_time == now_formatted):
            current_uv = uv_item.get("UV_VALUE")
            print("MATCH", uv_item)
    #    print(items)
    # print("max", int(max_uv))

    # print(current_uv, max_uv)
    if(current_uv == None):
        return None, None
    return int(current_uv), int(max_uv)


def get_openuv_uv(config):
    openuv_data = get_openuv_data(config)

    if openuv_data == None or openuv_data.get("result") == None:
        return None, None

    timezone = json.decode(config.get("location"))["timezone"]
    now = time.now().in_location(timezone)

    openuv_result = openuv_data["result"]

    current_uv = openuv_result["uv"]
    current_dt = time.parse_time(openuv_result["uv_time"]).in_location(timezone)

    max_uv = openuv_result["uv_max"]
    max_dt = time.parse_time(openuv_result["uv_max_time"]).in_location(timezone)

    # interpolate between last result and max
    current_uv = current_uv + (max_uv - current_uv) * (now - current_dt).seconds / (max_dt - current_dt).seconds

    if max_dt > now:
        return current_uv, max_uv
    else:
        return current_uv, current_uv

def get_epa_uv_data(config):
    
    zip_code = config.get("zip_code")
    if(len(zip_code) != 5):
        print("incorrect zip length for zip", zip_code)
        return None
    print("zip code is %s" % (zip_code))
    query = "https://data.epa.gov/efservice/getEnvirofactsUVHOURLY/ZIP/%s/JSON" % (zip_code)

    res = http.get(url = query, headers = {}, ttl_seconds = EPA_UV_REFRESH_RATE)


    if res.status_code != 200:
        print("EPA UV request failed with status %d", res.status_code)
        return None

    return res.json()

def get_openuv_data(config):
    api_key = config.get("api_key", None)
    location = config.get("location", None)

    if api_key == None:
        print("Config missing api_key")
        return None
    if location == None:
        print("Config missing location")
        return None

    location = json.decode(location)
    query = "%s?lat=%s&lng=%s" % (OPENUV_URL, location["lat"], location["lng"])

    res = http.get(url = query, headers = {"x-access-token": api_key}, ttl_seconds = OPENWEATHER_REFRESH_RATE)

    if res.status_code != 200:
        print("OpenUV request failed with status %d", res.status_code)
        return None

    return res.json()

def get_openweather_uv(config):
    weather_data = get_openweather_data(config)

    if weather_data == None:
        return None, None

    timezone = json.decode(config.get("location"))["timezone"]
    now = time.now().in_location(timezone)

    current_uv = weather_data["current"]["uvi"]
    current_dt = time.from_timestamp(math.floor(weather_data["current"]["dt"])).in_location(timezone)

    max_uv = 0

    next_hour_uv = None
    next_hour_dt = None

    for hour_weather in weather_data["hourly"]:
        hour_timestamp = time.from_timestamp(math.floor(hour_weather["dt"])).in_location(timezone)
        hour_uvi = hour_weather["uvi"]

        if hour_timestamp > now and hour_timestamp.day == now.day:
            if hour_uvi > max_uv:
                max_uv = hour_uvi

        if hour_timestamp > now and next_hour_uv == None:
            next_hour_uv = hour_uvi
            next_hour_dt = hour_timestamp

    # interpolate between last result and next hour
    if next_hour_uv != None and next_hour_dt != None:
        current_uv = current_uv + (next_hour_uv - current_uv) * (now - current_dt).seconds / (next_hour_dt - current_dt).seconds

    if current_uv > max_uv:
        max_uv = current_uv

    return current_uv, max_uv

def get_openweather_data(config):
    api_key = config.get("api_key", None)
    location = config.get("location", None)

    if api_key == None:
        print("Config missing api_key")
        return None
    if location == None:
        print("Config missing location")
        return None

    location = json.decode(location)
    query = "%s?lat=%s&lon=%s&appid=%s" % (OPENWEATHERMAP_URL, location["lat"], location["lng"], api_key)

    res = http.get(url = query, ttl_seconds = OPENWEATHER_REFRESH_RATE)

    if res.status_code != 200:
        print("Open Weather request failed with status %d", res.status_code)
        return None

    return res.json()

def get_schema():
    return schema.Schema(
        version = "1",
        fields = [
            schema.Text(
                id = "zip_code",
                name = "ZIP Code",
                desc = "Enter 5 digit zip code",
                icon = "certificate",
            ),
            schema.Location(
                id = "location",
                name = "Location",
                icon = "locationDot",
                desc = "Location for which to display UV index",
            ),
        ],
    )
