import io
import logging
import os
from dotenv import load_dotenv
from services.firebase_service import get_firestore_client

load_dotenv()
logger = logging.getLogger(__name__)


def _build_system_instruction(language: str) -> str:
    """Builds a comprehensive, flexible system instruction for HunarSathi Business Guide.

    Shapes HOW Gemini should respond rather than enforcing rigid, canned templates.
    """
    lang_name = "Hindi" if language == "hi" else ("Marathi" if language == "mr" else "English")
    lang_guidance = {
        "hi": "उत्तर सरल, आदरयुक्त और स्वाभाविक हिंदी में (Devanagari script) दें। कारीगर को सम्मानपूर्वक 'शिल्पकार जी' कहकर संबोधित करें।",
        "mr": "उत्तर शुद्ध, आदरयुक्त आणि सहज मराठीत (Devanagari script) द्या. कारागिरास 'शिल्पकार जी' म्हणून आदराने संबोधा.",
        "en": "Respond in warm, respectful, natural English. Address the user warmly as 'Artisan' or by their name if available."
    }.get(language, "Respond in warm, respectful, natural English.")

    return f"""You are "HunarSathi Business Guide" (हुनरसाथी बिज़नेस गाइड / हुनरसाथी व्यवसाय मार्गदर्शक) — a knowledgeable, warm, and encouraging advisor dedicated to empowering Indian rural, traditional, and indigenous artisans, handloom weavers, and craftspeople.

CORE IDENTITY & LANGUAGE:
- You speak fluently in {lang_name} ({lang_guidance}).
- Maintain a warm, encouraging, respectful, and peer-like tone at all times.
- Never be condescending or excessively bureaucratic; explain business concepts simply and practically.

SCOPE OF EXPERTISE:
You confidently and accurately assist artisans across these key areas:
1. Business & Commercial Strategy:
   - Pricing formulas and cost calculation: breaking down raw material expenses, skilled labor hours/wages, firing/fuel/workshop overheads, protective packaging costs, platform fees, and sustainable profit margins.
   - Packaging & Logistics: safe multi-layer packaging for fragile items (terracotta, ceramics, glassware, brass), unboxing aesthetics, and courier readiness.
   - Seasonal Demand & Festivals: planning stock and gift combos for Diwali, Rakhi, Holi, festive wedding seasons, local melas, and corporate gifting.
   - Customer Relations & Growth: handling customer queries, writing compelling product descriptions, photography tips with basic smartphones, and selling online through e-commerce or HunarSathi.
2. Craft & Cultural Heritage:
   - Deep knowledge of traditional Indian handicrafts, folk art forms, and heritage craft traditions (e.g., Madhubani painting, Dhokra / lost-wax brass casting, Warli art, Pattachitra, terracotta pottery, handloom textiles like Banarasi, Chanderi, Paithani, block printing like Bagru/Ajrakh, wood carving, etc.).
   - Craft histories, cultural symbolism, authentic techniques, and regional artisan cluster contexts across Indian states.
   - Helping artisans articulate their unique craft stories to connect emotionally with modern buyers.
3. Tangentially Related Artisan Matters:
   - Government welfare schemes and artisan support programs (e.g., PM Vishwakarma Yojana, Pehchan Artisan ID card, Ambedkar Hastshilp Vikas Yojana, Mudra loans, One District One Product (ODOP), craft marketing exhibitions like Dilli Haat and Saras Mela).
   - Raw material sourcing centers and artisan cooperatives.
   - When discussing government schemes, provide clear, helpful overviews using your general knowledge, and explicitly advise the artisan to verify exact eligibility criteria, documents, or current deadlines on official government portals (such as craftclusters.gov.in or pmvishwakarma.gov.in) or at their local District Industries Centre (DIC), as government policies are subject to periodic updates.

HANDLING OFF-TOPIC / UNRELATED QUESTIONS:
- If a user asks something completely outside crafts, business, or Indian culture (e.g., "what's the weather today", "tell me a joke", cricket scores, movies, coding/programming):
  - Do NOT issue a rigid, robotic error or generic canned rejection.
  - Politely and briefly acknowledge the question. If it is simple and harmless (like asking for a lighthearted joke), feel free to share a brief, wholesome joke or friendly greeting first.
  - Then gracefully and naturally steer the conversation back to your core mission — for instance:
    "That's a bit outside what I can help with best — I'm here primarily to help you with your craft business, fair pricing, packaging, and Indian art traditions. Is there something about your craft work or sales I can help you with today?"
  - Let this redirection feel natural, friendly, and conversational in {lang_name}.

RESPONSE STYLE:
- Genuinely address the SPECIFIC question asked. Reference actual details from the user's question (e.g., if they ask about silk saree pricing, talk specifically about silk yarn costs, zari, loom time, and saree margins; if they ask about terracotta pots in Maharashtra, address pottery in Maharashtra and local rates).
- NEVER output a generic copy-paste or pre-written template.
- Make answers concise, structured, and easy to read on mobile screens (use clean bullet points or steps when giving calculations or practical advice).
"""


def _get_artisan_context(artisan_id: str, artisan_profile: dict = None) -> dict:
    """Fetches real artisan catalog and sales context from Firestore,
    supplemented by any profile details passed from client.
    """
    products = []
    orders = []

    db = get_firestore_client()
    if db:
        try:
            prod_docs = db.collection('products').where('artisan_id', '==', artisan_id).stream()
            products = [doc.to_dict() | {"id": doc.id} for doc in prod_docs]
            if not products:
                all_prod = db.collection('products').limit(5).stream()
                products = [doc.to_dict() | {"id": doc.id} for doc in all_prod]

            order_docs = db.collection('orders').limit(5).stream()
            orders = [doc.to_dict() | {"id": doc.id} for doc in order_docs]
        except Exception as e:
            logger.warning(f"Could not fetch Firestore context for assistant ({e})")

    if not products:
        products = [
            {
                "title": "पारंपरिक टेराकोटा चाय कुल्हड़ सेट (Terracotta Kulhad Set)",
                "category": "Pottery",
                "price": 350,
                "stock_quantity": 18
            },
            {
                "title": "हाथ से बनी मधुबनी पेंटिंग (Handmade Madhubani Painting)",
                "category": "Painting",
                "price": 850,
                "stock_quantity": 6
            }
        ]

    if not orders:
        orders = [
            {
                "item_name": "Terracotta Chai Kulhad Set (6 pcs)",
                "amount": 350,
                "status": "Delivered",
                "date": "2026-09-02"
            }
        ]

    categories = list(set(p.get("category", "Handicraft") for p in products))

    profile_info = {
        "name": (artisan_profile or {}).get("name") or "शिल्पकार साथी",
        "craft_type": (artisan_profile or {}).get("craft") or (artisan_profile or {}).get("craft_type") or (categories[0] if categories else "हस्तशिल्प"),
        "cluster": (artisan_profile or {}).get("region") or (artisan_profile or {}).get("artisanCluster") or "भारत",
        "experience": (artisan_profile or {}).get("experience") or (artisan_profile or {}).get("craftExperience") or "",
        "story": (artisan_profile or {}).get("story") or (artisan_profile or {}).get("artisanStory") or "",
    }

    return {
        "artisan_id": artisan_id,
        "profile": profile_info,
        "products": products,
        "orders": orders,
        "categories": categories,
        "total_products": len(products),
        "total_orders": len(orders)
    }


def ask_business_assistant(
    artisan_id: str,
    question: str,
    language: str = "hi",
    conversation_history: list = None,
    artisan_profile: dict = None
) -> dict:
    """Answers artisan business, craft, pricing, cultural, and related questions

    using Google Gemini AI freely without hardcoded templates or canned keyword responses.
    """
    if not question or not question.strip():
        return {
            "success": False,
            "error": "Empty question provided",
            "friendly_error": "कृपया अपना सवाल पूछें (Please ask your question)"
        }

    raw_question = question.strip()
    norm_lang = "hi"
    if language in ["en", "english"]:
        norm_lang = "en"
    elif language in ["mr", "marathi"]:
        norm_lang = "mr"

    # Fetch store context and artisan profile
    context = _get_artisan_context(artisan_id, artisan_profile)
    profile = context.get("profile", {})

    products_summary = "\n".join([
        f"- {p.get('title', 'Craft Item')} | श्रेणी: {p.get('category', 'Craft')} | कीमत: ₹{p.get('price', 0)} | स्टॉक: {p.get('stock_quantity', p.get('stock', 0))}"
        for p in context["products"][:6]
    ])

    orders_summary = "\n".join([
        f"- {o.get('item_name', 'Order')} | ₹{o.get('amount', 0)} | स्थिति: {o.get('status', 'Pending')}"
        for o in context["orders"][:4]
    ])

    # Format multi-turn conversation history if available
    history_formatted = ""
    if conversation_history and isinstance(conversation_history, list):
        recent_history = conversation_history[-8:]
        for turn in recent_history:
            role = "शिल्पकार (Artisan)" if turn.get("role") in ["user", "artisan"] else "व्यापार सहायक (Assistant)"
            text = turn.get("text") or turn.get("content") or ""
            if text:
                history_formatted += f"{role}: {text}\n"

    api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")

    if not api_key:
        logger.error("GEMINI_API_KEY is not set in environment.")
        return {
            "success": False,
            "error": "GEMINI_API_KEY not configured",
            "friendly_error": "AI सहायक सेवा वर्तमान में उपलब्ध नहीं है। कृपया व्यवस्थापक से संपर्क करें।",
            "answer": "AI सहायक सेवा वर्तमान में उपलब्ध नहीं है। कृपया व्यवस्थापक से संपर्क करें।",
            "language": norm_lang
        }

    try:
        from google import genai
        from google.genai import types

        client = genai.Client(api_key=api_key)
        system_instruction = _build_system_instruction(norm_lang)

        lang_label = "Hindi" if norm_lang == "hi" else ("Marathi" if norm_lang == "mr" else "English")

        user_prompt = f"""ARTISAN PROFILE & CONTEXT:
- Name: {profile.get('name', 'Artisan')}
- Craft Specialty: {profile.get('craft_type', 'Handicraft')}
- Region / Cluster: {profile.get('cluster', 'India')}
{f"- Experience: {profile.get('experience')}" if profile.get('experience') else ""}
{f"- Craft Story: {profile.get('story')}" if profile.get('story') else ""}

CURRENT STORE CATALOG:
{products_summary if products_summary else "(No products listed yet)"}

RECENT ORDERS:
{orders_summary if orders_summary else "(No recent orders)"}

CONVERSATION HISTORY:
{history_formatted if history_formatted else "(Start of conversation)"}

ARTISAN'S QUESTION:
"{raw_question}"

Please provide your genuine, specific response as HunarSathi Business Guide in {lang_label}:"""

        # Models prioritized by availability and speed in Google GenAI SDK
        models_to_try = [
            "gemini-3.5-flash-lite",
            "gemini-3.6-flash",
            "gemini-3.5-flash",
            "gemini-flash-latest"
        ]

        response_text = None
        last_error = None

        for model_name in models_to_try:
            try:
                res = client.models.generate_content(
                    model=model_name,
                    contents=user_prompt,
                    config=types.GenerateContentConfig(
                        system_instruction=system_instruction,
                        temperature=0.6,
                        max_output_tokens=1000,
                    )
                )
                if res and res.text and res.text.strip():
                    response_text = res.text.strip()
                    logger.info(f"Gemini generation successful using model {model_name}")
                    break
            except Exception as ex:
                last_error = ex
                logger.warning(f"Gemini model {model_name} failed: {ex}")

        if response_text:
            return {
                "success": True,
                "artisan_id": artisan_id,
                "question": raw_question,
                "answer": response_text,
                "language": norm_lang,
                "context_summary": {
                    "products_count": context["total_products"],
                    "orders_count": context["total_orders"],
                    "categories": context["categories"]
                }
            }
        else:
            raise RuntimeError(f"All Gemini models failed. Last error: {last_error}")

    except Exception as e:
        logger.error(f"Error communicating with Gemini API: {e}", exc_info=True)
        friendly_err = {
            "mr": "सध्या AI सहाय्यकाशी संपर्क साधण्यात अडचण येत आहे. कृपया आपले इंटरनेट तपासा आणि थोड्या वेळाने पुन्हा विचारा.",
            "en": "Currently unable to reach the AI Business Guide. Please check your network connection and try again shortly.",
            "hi": "वर्तमान में AI व्यापार मार्गदर्शक से संपर्क करने में समस्या आ रही है। कृपया अपना इंटरनेट कनेक्शन जांचें और कुछ समय बाद पुनः प्रयास करें।"
        }.get(norm_lang, "Unable to reach AI assistant. Please try again.")

        return {
            "success": False,
            "artisan_id": artisan_id,
            "question": raw_question,
            "error": str(e),
            "friendly_error": friendly_err,
            "answer": friendly_err,
            "language": norm_lang
        }


def transcribe_assistant_speech(audio_bytes: bytes, filename: str = "assistant_audio.wav", language: str = "hi") -> dict:
    """Transcribes artisan spoken question using Gemini multimodal STT with fallback to speech_service."""
    if not audio_bytes or len(audio_bytes) < 80:
        return {
            "success": False,
            "transcription": "",
            "error": "Audio recording is empty or too short",
            "friendly_error": "ऑडियो बहुत छोटा या खाली है, कृपया दोबारा बोलें (Recording too short, please speak again)"
        }

    api_key = os.getenv("GEMINI_API_KEY") or os.getenv("GOOGLE_API_KEY")

    # 1. Try Gemini Multimodal Speech Transcription
    if api_key:
        try:
            from google import genai
            from google.genai import types

            client = genai.Client(api_key=api_key)

            # Determine mime type
            mime_type = "audio/wav"
            if filename.endswith(".mp3"):
                mime_type = "audio/mp3"
            elif filename.endswith(".ogg"):
                mime_type = "audio/ogg"
            elif filename.endswith(".m4a"):
                mime_type = "audio/m4a"
            elif filename.endswith(".webm"):
                mime_type = "audio/webm"

            stt_prompt = (
                "You are an accurate speech-to-text transcriber for Indian craftspeople. "
                "Transcribe the following audio recording verbatim into the language spoken (Hindi in Devanagari, Marathi in Devanagari, or English). "
                "Return ONLY the transcribed text. Do not add quotes, explanation, punctuation marks like timestamps, or any other words."
            )

            models = ["gemini-3.6-flash", "gemini-3.5-flash-lite", "gemini-3.5-flash"]
            for m in models:
                try:
                    res = client.models.generate_content(
                        model=m,
                        contents=[
                            types.Part.from_bytes(data=audio_bytes, mime_type=mime_type),
                            stt_prompt
                        ]
                    )
                    if res and res.text and res.text.strip():
                        transcribed = res.text.strip().strip('"\'')
                        logger.info(f"Gemini voice transcription successful: '{transcribed}'")
                        return {
                            "success": True,
                            "transcription": transcribed,
                            "language": language
                        }
                except Exception as mex:
                    logger.warning(f"Gemini STT model {m} failed: {mex}")
        except Exception as ex:
            logger.warning(f"Gemini multimodal STT failed ({ex}). Falling back to Google Speech Recognition.")

    # 2. Fallback to speech_service (Google SpeechRecognition engine)
    try:
        from services.speech_service import transcribe_audio
        res = transcribe_audio(audio_bytes, filename=filename, lang_code=language)
        if res.get("success") and res.get("transcript"):
            return {
                "success": True,
                "transcription": res.get("transcript", "").strip(),
                "language": language
            }
        else:
            return {
                "success": False,
                "transcription": "",
                "error": res.get("error") or "Could not transcribe audio",
                "friendly_error": res.get("friendly_error") or "आवाज़ स्पष्ट नहीं सुनाई दी, कृपया दोबारा बोलें"
            }
    except Exception as e:
        logger.error(f"Fallback STT error: {e}")
        return {
            "success": False,
            "transcription": "",
            "error": str(e),
            "friendly_error": "आवाज़ को टेक्स्ट में बदलने में समस्या आई"
        }
