# backend/main.py

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

# إنشاء نسخة من التطبيق
app = FastAPI()

# السماح بالطلبات من جميع المصادر (CORS)
# هذا مهم جدًا للسماح لتطبيق فلاتر (الذي يعمل على نطاق مختلف) بالوصول إلى الـ API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # يسمح لجميع المصادر بالوصول
    allow_credentials=True,
    allow_methods=["*"],  # يسمح بجميع أنواع الطلبات (GET, POST, etc.)
    allow_headers=["*"],
)

# بيانات وهمية بسيطة
MESSAGES_DB = [
    {"id": 1, "text": "أهلاً بك في تطبيق فلاتر المتصل بـ Render!"},
    {"id": 2, "text": "هذه الرسالة قادمة من واجهة خلفية مكتوبة بـ Python."},
    {"id": 3, "text": "FastAPI يجعل بناء الـ APIs سهلاً وسريعاً."},
]

@app.get("/")
def read_root():
    """نقطة نهاية ترحيبية للتأكد من أن الـ API تعمل."""
    return {"status": "API is running!"}


@app.get("/messages")
def get_messages():
    """نقطة النهاية الرئيسية التي سترجع قائمة الرسائل."""
    return {"messages": MESSAGES_DB}

