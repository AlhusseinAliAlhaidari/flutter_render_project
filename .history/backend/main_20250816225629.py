# backend/main.py

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List

# --- نماذج البيانات (Pydantic Models) ---
# هذا يضمن أن البيانات القادمة مع الطلبات لها بنية صحيحة
class Message(BaseModel):
    id: int
    text: str

class CreateMessage(BaseModel):
    text: str # عند الإنشاء، لا نحتاج لإرسال ID

# --- قاعدة بيانات وهمية في الذاكرة ---
# سنبدأ ببعض البيانات الأولية
MESSAGES_DB: List[Message] = [
    Message(id=1, text="أهلاً بك في تطبيق فلاتر المتصل بـ Render!"),
    Message(id=2, text="اسحب لليمين لحذف رسالة"),
    Message(id=3, text="اضغط مطولاً لتعديل رسالة"),
]

# متغير لتتبع الـ ID التالي الذي سيتم استخدامه
next_id = 4

# --- إعدادات التطبيق ---
app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- نقاط النهاية (API Endpoints) ---

@app.get("/")
def read_root():
    return {"status": "API is running!"}

# 1. جلب كل الرسائل (Read)
@app.get("/messages", response_model=List[Message])
def get_messages():
    return MESSAGES_DB

# 2. إضافة رسالة جديدة (Create)
@app.post("/messages", response_model=Message, status_code=201)
def create_message(message_data: CreateMessage):
    global next_id
    new_message = Message(id=next_id, text=message_data.text)
    MESSAGES_DB.append(new_message)
    next_id += 1
    return new_message

# 3. تعديل رسالة موجودة (Update)
@app.put("/messages/{message_id}", response_model=Message)
def update_message(message_id: int, message_data: CreateMessage):
    # ابحث عن الرسالة في القائمة
    for i, msg in enumerate(MESSAGES_DB):
        if msg.id == message_id:
            # قم بتحديث نص الرسالة
            MESSAGES_DB[i].text = message_data.text
            return MESSAGES_DB[i]
    # إذا لم يتم العثور على الرسالة، أرجع خطأ 404
    raise HTTPException(status_code=404, detail="Message not found")

# 4. حذف رسالة (Delete)
@app.delete("/messages/{message_id}", status_code=204)
def delete_message(message_id: int):
    # ابحث عن الرسالة
    message_to_delete = next((msg for msg in MESSAGES_DB if msg.id == message_id), None)
    if message_to_delete:
        MESSAGES_DB.remove(message_to_delete)
        # لا نرجع أي محتوى عند الحذف الناجح (status 204)
        return
    # إذا لم يتم العثور عليها، أرجع خطأ 404
    raise HTTPException(status_code=404, detail="Message not found")

