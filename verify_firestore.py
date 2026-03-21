import json
import urllib.request
import urllib.error

# Config from your GoogleService-Info.plist
API_KEY = "REDACTED_FIREBASE_KEY"
PROJECT_ID = "cinemy-backend"

def sign_in_anonymously():
    url = f"https://identitytoolkit.googleapis.com/v1/accounts:signUp?key={API_KEY}"
    data = json.dumps({"returnSecureToken": True}).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers={"Content-Type": "application/json"})
    
    try:
        with urllib.request.urlopen(req) as response:
            result = json.loads(response.read().decode())
            print("✅ Authentication successful")
            return result["idToken"], result["localId"]
    except urllib.error.HTTPError as e:
        print(f"❌ Authentication failed: {e.code} {e.read().decode()}")
        return None, None

def write_user_data(id_token, uid, target_uid, data_fields):
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/users/{target_uid}"
    
    # Construct Firestore JSON format
    fields = {}
    for k, v in data_fields.items():
        fields[k] = {"stringValue": v}
        
    body = {
        "fields": fields
    }
    
    data = json.dumps(body).encode("utf-8")
    req = urllib.request.Request(url, data=data, headers={
        "Content-Type": "application/json",
        "Authorization": f"Bearer {id_token}"
    }, method="PATCH")
    
    try:
        with urllib.request.urlopen(req) as response:
            print(f"✅ Write successful to users/{target_uid}")
            return True
    except urllib.error.HTTPError as e:
        print(f"⚠️ Write response for users/{target_uid}: {e.code}") # {e.reason}
        return False

def read_user_data(id_token, target_uid):
    url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/users/{target_uid}"
    req = urllib.request.Request(url, headers={
        "Authorization": f"Bearer {id_token}"
    })
    
    try:
        with urllib.request.urlopen(req) as response:
            print(f"✅ Read successful from users/{target_uid}")
            return True
    except urllib.error.HTTPError as e:
        print(f"⚠️ Read response for users/{target_uid}: {e.code}")
        return False

def run_checks():
    print("--- 1. Authenticating (Simulating App Login) ---")
    id_token, uid = sign_in_anonymously()
    if not id_token:
        return

    print(f"\n--- 2. Testing Write Permission (Own Data: users/{uid}) ---")
    # Should SUCCEED
    success = write_user_data(id_token, uid, uid, {"test_field": "verified_by_antigravity"})
    if success:
        print("   -> PASS: You can write to your own record.")
    else:
        print("   -> FAIL: Could not write to own record.")

    print(f"\n--- 3. Testing Read Permission (Own Data) ---")
    # Should SUCCEED
    success = read_user_data(id_token, uid)
    if success:
         print("   -> PASS: You can read your own record.")
    else:
         print("   -> FAIL: Could not read own record.")

    print(f"\n--- 4. Testing Write Security (Others' Data) ---")
    # Should FAIL (403)
    other_uid = "someone_else_123"
    success = write_user_data(id_token, uid, other_uid, {"hacked": "true"})
    if not success:
        print("   -> PASS: Correctly blocked writing to another user's record.")
    else:
        print("   -> FAIL: SECURITY RISK! You were able to write to another user's record.")

if __name__ == "__main__":
    run_checks()
