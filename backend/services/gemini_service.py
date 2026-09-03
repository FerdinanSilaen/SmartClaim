import os
from typing import Final

from google import genai


GEMINI_MODEL: Final[str] = os.getenv(
    "GEMINI_MODEL",
    "gemini-3.5-flash-lite",
)


class GeminiConfigurationError(RuntimeError):
    """Terjadi ketika konfigurasi Gemini belum tersedia."""


class GeminiAnalysisError(RuntimeError):
    """Terjadi ketika Gemini gagal menghasilkan analisis."""


def _get_client() -> genai.Client:
    """
    Membuat Gemini client menggunakan API key
    dari environment variable Windows.
    """

    api_key = os.getenv("GEMINI_API_KEY")

    if not api_key:
        raise GeminiConfigurationError(
            "GEMINI_API_KEY belum tersedia pada environment backend."
        )

    return genai.Client(api_key=api_key)


def generate_claim_analysis(
    *,
    incurred_amount: float,
    predicted_approved_amount: float,
    estimated_difference: float,
    approval_ratio: float,
    coverage_id: str,
    length_of_stay: float,
) -> str:
    """
    Menghasilkan analisis singkat berdasarkan hasil prediksi Random Forest.

    Data yang dikirim ke Gemini hanya berupa hasil prediksi agregat.
    Data pribadi, nomor polis, nomor klaim, dan diagnosis tidak dikirim.
    """

    prompt = f"""
Anda adalah asisten analisis klaim asuransi kesehatan
pada aplikasi SmartClaim.

Analisislah hasil prediksi Random Forest berikut:

- Incurred Amount: Rp{incurred_amount:,.0f}
- Predicted Approved Amount: Rp{predicted_approved_amount:,.0f}
- Estimated Difference: Rp{estimated_difference:,.0f}
- Predicted Approval Ratio: {approval_ratio:.2f}%
- Coverage: {coverage_id}
- Length of Stay: {length_of_stay:.0f} hari

Ketentuan jawaban:

1. Gunakan Bahasa Indonesia yang profesional dan mudah dipahami.
2. Buat maksimal tiga paragraf pendek.
3. Jelaskan nilai pengajuan dan estimasi nilai yang disetujui.
4. Jelaskan selisih antara nilai pengajuan dan hasil prediksi.
5. Jelaskan bahwa predicted approval ratio adalah perbandingan
   antara estimasi nilai approved dengan nilai incurred.
6. Jangan menyebut approval ratio sebagai probabilitas,
   peluang, tingkat keyakinan, atau kemungkinan klaim diterima.
7. Jangan menyatakan bahwa klaim pasti diterima atau ditolak.
8. Jangan memberikan diagnosis atau dugaan medis.
9. Tegaskan bahwa hasil ini merupakan estimasi model Random Forest.
10. Jangan menggunakan tabel atau markdown heading.
11. Jangan mengarang informasi di luar data yang diberikan.
12. Gunakan format mata uang Indonesia yang mudah dibaca.
""".strip()

    try:
        client = _get_client()

        interaction = client.interactions.create(
            model=GEMINI_MODEL,
            input=prompt,
        )

        analysis = (interaction.output_text or "").strip()

        if not analysis:
            raise GeminiAnalysisError(
                "Gemini tidak mengembalikan teks analisis."
            )

        return analysis

    except GeminiConfigurationError:
        raise

    except GeminiAnalysisError:
        raise

    except Exception as error:
        raise GeminiAnalysisError(
            f"Gagal menghasilkan analisis Gemini: {error}"
        ) from error