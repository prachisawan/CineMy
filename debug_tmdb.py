import requests
import json

api_key = "REDACTED_TMDB_KEY"

def search(type, query, year_param, year):
    url = f"https://api.themoviedb.org/3/search/{type}?api_key={api_key}&query={query}&page=1&include_adult=false&language=en-US&{year_param}={year}"
    print(f"Requesting: {url}")
    try:
        response = requests.get(url)
        data = response.json()
        print(f"--- {type.upper()} Results ---")
        print(f"Total Results: {data.get('total_results', 'N/A')}")
        results = data.get('results', [])
        for i, item in enumerate(results[:5]):
            title = item.get('title') or item.get('name') or "Unknown"
            print(f"{i+1}. {title} (ID: {item.get('id')})")
    except Exception as e:
        print(f"Error: {e}")

# Scenario: "Harry Potter"
# Check if Exact Matches exist.
# Check Ratings (to see if < 6.0 filter kills them).

print("\n--- TEST: 'Harry Potter' Search ---")
search("movie", "Harry Potter", "year", None)

# Also check exact match logic simulation
url = f"https://api.themoviedb.org/3/search/movie?api_key={api_key}&query=Harry+Potter&page=1&include_adult=false&language=en-US"
try:
    print(f"Requesting: {url}")
    data = requests.get(url).json()
    results = data.get('results', [])
    print(f"Total Results: {data.get('total_results')}")
    for i, item in enumerate(results[:10]):
        title = item.get('title')
        rating = item.get('vote_average')
        exact = (title.lower() == "harry potter")
        print(f"{i+1}. {title} (Rating: {rating}) [Exact: {exact}]")
except Exception as e:
    print(e)
