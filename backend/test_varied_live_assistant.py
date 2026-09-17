import json
import urllib.request
import sys

# Ensure UTF-8 output on Windows consoles
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except Exception:
        pass

API_URL = "http://127.0.0.1:5000/api/assistant/ask"

test_questions = [
    {
        "id": "a",
        "question": "what is the current price of pot in maharashtra",
        "language": "en",
        "label": "Regional Pricing Question"
    },
    {
        "id": "b",
        "question": "tell me about the history of Madhubani painting",
        "language": "en",
        "label": "Cultural / Art History Question"
    },
    {
        "id": "c",
        "question": "how is Dhokra metal casting done",
        "language": "en",
        "label": "Craft Technique Question"
    },
    {
        "id": "d",
        "question": "what government schemes exist for artisans in India",
        "language": "en",
        "label": "Tangential / Government Schemes Question"
    },
    {
        "id": "e",
        "question": "what's a good joke",
        "language": "en",
        "label": "Off-Topic / Redirect Question"
    },
    {
        "id": "f",
        "question": "how should I price my saree considering silk costs and my time",
        "language": "en",
        "label": "Specific Material & Time Pricing Question"
    }
]

def run_tests():
    results = {}
    for item in test_questions:
        print(f"\n{'='*70}", flush=True)
        print(f"RUNNING TEST {item['id'].upper()}: {item['label']}", flush=True)
        print(f"Question: \"{item['question']}\"", flush=True)
        print('='*70, flush=True)

        payload = {
            "artisan_id": "artisan_001",
            "question": item["question"],
            "language": item["language"]
        }

        req = urllib.request.Request(
            API_URL,
            data=json.dumps(payload).encode('utf-8'),
            headers={"Content-Type": "application/json"}
        )

        try:
            with urllib.request.urlopen(req, timeout=60) as resp:
                data = json.loads(resp.read().decode('utf-8'))
                answer = data.get("answer", "")
                results[item["id"]] = {
                    "question": item["question"],
                    "label": item["label"],
                    "success": data.get("success"),
                    "answer": answer
                }
                # Write to disk immediately
                with open("live_test_results.json", "w", encoding="utf-8") as f:
                    json.dump(results, f, ensure_ascii=False, indent=2)

                print(f"Status: {resp.status}", flush=True)
                print(f"Success: {data.get('success')}", flush=True)
                print(f"\n--- ACTUAL RESPONSE ---\n{answer}\n", flush=True)
        except Exception as e:
            print(f"ERROR on question {item['id']}: {e}", flush=True)
            if item["id"] not in results:
                results[item["id"]] = {"error": str(e)}

    print("\nAll tests completed and saved to live_test_results.json", flush=True)

if __name__ == "__main__":
    run_tests()
