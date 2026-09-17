import logging
from flask import Blueprint, jsonify, request
from services.assistant_service import ask_business_assistant, transcribe_assistant_speech

logger = logging.getLogger(__name__)

assistant_bp = Blueprint('assistant', __name__)


@assistant_bp.route('/ask', methods=['POST'])
def ask_assistant_endpoint():
    """Accepts free-text artisan business questions and returns empathetic,

    actionable advice from the Gemini AI Business Counselor.
    Supports multi-turn conversation history and artisan profile personalization.
    """
    try:
        data = request.get_json(silent=True) or {}

        artisan_id = data.get('artisan_id', 'artisan_001')
        question = data.get('question') or data.get('prompt') or data.get('message')
        language = data.get('language', 'hi')
        conversation_history = data.get('conversation_history') or data.get('history') or []
        artisan_profile = data.get('artisan_profile') or data.get('profile') or {}

        if not question or not str(question).strip():
            return jsonify({
                "success": False,
                "error": "Missing question in request body",
                "friendly_error": "कृपया अपना सवाल पूछें (Please provide your question)"
            }), 400

        result = ask_business_assistant(
            artisan_id=artisan_id,
            question=str(question),
            language=language,
            conversation_history=conversation_history,
            artisan_profile=artisan_profile
        )

        return jsonify(result), 200

    except Exception as e:
        logger.error(f"Error in /api/assistant/ask: {e}", exc_info=True)
        return jsonify({
            "success": False,
            "error": str(e),
            "friendly_error": "व्यापार सहायक से उत्तर प्राप्त करने में समस्या आई (Assistant encountered an error)"
        }), 500


@assistant_bp.route('/voice-to-text', methods=['POST'])
def assistant_voice_to_text():
    """Accepts recorded audio from artisan microphone,

    transcribes it via Gemini / Google Speech, and returns the transcription.
    The client populates the text field so the artisan can review before asking.
    """
    try:
        language = request.form.get('language') or request.args.get('language') or 'hi'
        audio_file = request.files.get('audio') or request.files.get('file')

        # Direct text fallback / override for testing
        direct_text = request.form.get('transcript') or request.form.get('text')
        if not direct_text and request.is_json:
            data = request.get_json(silent=True) or {}
            direct_text = data.get('transcript') or data.get('text')
            language = data.get('language', language)

        if direct_text and direct_text.strip():
            return jsonify({
                "success": True,
                "transcription": direct_text.strip(),
                "language": language
            }), 200

        if not audio_file:
            return jsonify({
                "success": False,
                "error": "No audio file provided",
                "friendly_error": "कोई ऑडियो फ़ाइल नहीं मिली (No audio received)"
            }), 400

        audio_bytes = audio_file.read()
        filename = audio_file.filename or "assistant_voice.wav"

        result = transcribe_assistant_speech(
            audio_bytes=audio_bytes,
            filename=filename,
            language=language
        )

        status_code = 200 if result.get("success") else 400
        return jsonify(result), status_code

    except Exception as e:
        logger.error(f"Error in /api/assistant/voice-to-text: {e}", exc_info=True)
        return jsonify({
            "success": False,
            "error": str(e),
            "friendly_error": "आवाज़ पहचानने में त्रुटि आई (Failed to process voice)"
        }), 500
