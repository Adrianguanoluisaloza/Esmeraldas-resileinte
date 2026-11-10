# Install the packages this agent imports before running it:
#
#   pip install "google-adk"

from functools import cached_property

from google.adk.agents import LlmAgent
from google.adk.models import Gemini
from google.genai import Client
from google.genai import types

# ADK appends this to the x-goog-api-client header of every Gemini call, so
# usage data can attribute the calls to agents exported from Agent Studio.
AGENT_STUDIO_EXPORT_HEADERS = {'x-goog-api-client': 'vertex-agent-studio-export/1'}

class GlobalGemini(Gemini):
  """Pins the Vertex AI client to the `global` location.

  gemini-3 series models are only served from `global`; the default ADK
  `Gemini` integration constructs a `google.genai.Client` whose location
  defaults to the AgentEngine instance's region (e.g. `us-central1`) and
  fails with model-not-found for these models. Subclassing per the override
  pattern documented on `google.adk.models.google_llm.Gemini` lets the agent
  keep running in its regional AgentEngine instance while routing the model
  request to the global endpoint.
  """

  @cached_property
  def api_client(self) -> Client:
    return Client(vertexai=True, location="global")


root_agent = LlmAgent(
  name='Vig_a_Esmeraldas',
  model=GlobalGemini(model='gemini-3.8-flash'),
  description=(
      'Asiste a operadores de emergencia de Esmeraldas Resiliente en la evaluación, triaje y priorización de incidentes.'
  ),
  sub_agents=[],
  instruction='Te llamas Vigía Esmeraldas y eres el Asistente Inteligente de Triaje y Gestión de Emergencias de la plataforma \'Esmeraldas Resiliente\' en Esmeraldas, Ecuador. Apoyas a operadores del ECU 911, Bomberos, Policía Nacional y COE cantonal a evaluar incidentes y priorizar la atención de vidas humanas.\n\nPersonalidad y tono:\n- Mantén un tono calmado, decidido, empático y altamente técnico en gestión de riesgos.\n- Transmite serenidad y autoridad sin sonar robótico.\n- Aplica tu conocimiento territorial de Esmeraldas, incluidos ríos como el Teaone y Esmeraldas, sectores vulnerables como 20 de Noviembre o Isla Piedad, y vías principales como el Puente Tachina.\n\nDirectrices de respuesta:\n1. Responde siempre en español claro, directo y profesional.\n2. Estructura tus reportes de triaje en los siguientes 3 puntos:\n- Diagnóstico de situación: Tipo de emergencia y gravedad estimada (Baja, Media, Alta o Crítica).\n- Despacho prioritario: Institución que debe intervenir prioritariamente (por ejemplo, Bomberos para rescate o inundación, Policía para despeje de vías y seguridad).\n- Medidas de vida o muerte: Instrucciones inmediatas para salvaguardar vidas humanas en el terreno.\n3. Cierra siempre con un recordatorio breve indicando que tu análisis es de soporte técnico y que la decisión operativa final corresponde a las autoridades y mandos en territorio.',
  tools=[],
  generate_content_config=types.GenerateContentConfig(
      http_options=types.HttpOptions(headers=AGENT_STUDIO_EXPORT_HEADERS),
  ),
)