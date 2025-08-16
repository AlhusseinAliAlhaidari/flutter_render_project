# backend/main.py

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Literal
from datetime import datetime

# --- نماذج البيانات المحاسبية (Pydantic Models) ---

# النوع: إما إيراد أو مصروف
TransactionType = Literal["income", "expense"]

class Transaction(BaseModel):
    id: int
    description: str
    amount: float
    type: TransactionType
    date: datetime

class CreateTransaction(BaseModel):
    description: str
    amount: float
    type: TransactionType

# --- قاعدة بيانات وهمية في الذاكرة ---
TRANSACTIONS_DB: List[Transaction] = [
    Transaction(id=1, description="راتب الشهر", amount=5000.0, type="income", date=datetime.now()),
    Transaction(id=2, description="إيجار المكتب", amount=1500.0, type="expense", date=datetime.now()),
    Transaction(id=3, description="فاتورة كهرباء", amount=250.0, type="expense", date=datetime.now()),
]
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
    return {"status": "Accounting API is running!"}

# 1. جلب كل الحركات (Read)
@app.get("/transactions", response_model=List[Transaction])
def get_transactions():
    # ترتيب الحركات من الأحدث إلى الأقدم
    return sorted(TRANSACTIONS_DB, key=lambda t: t.date, reverse=True)

# نقطة نهاية جديدة: جلب ملخص الحسابات
@app.get("/summary")
def get_summary():
    total_income = sum(t.amount for t in TRANSACTIONS_DB if t.type == 'income')
    total_expense = sum(t.amount for t in TRANSACTIONS_DB if t.type == 'expense')
    balance = total_income - total_expense
    return {
        "total_income": total_income,
        "total_expense": total_expense,
        "balance": balance
    }

# 2. إضافة حركة جديدة (Create)
@app.post("/transactions", response_model=Transaction, status_code=201)
def create_transaction(transaction_data: CreateTransaction):
    global next_id
    # التحقق من أن المبلغ موجب
    if transaction_data.amount <= 0:
        raise HTTPException(status_code=400, detail="Amount must be positive")
        
    new_transaction = Transaction(
        id=next_id,
        description=transaction_data.description,
        amount=transaction_data.amount,
        type=transaction_data.type,
        date=datetime.now()
    )
    TRANSACTIONS_DB.append(new_transaction)
    next_id += 1
    return new_transaction

# 3. حذف حركة (Delete)
@app.delete("/transactions/{transaction_id}", status_code=204)
def delete_transaction(transaction_id: int):
    transaction_to_delete = next((t for t in TRANSACTIONS_DB if t.id == transaction_id), None)
    if transaction_to_delete:
        TRANSACTIONS_DB.remove(transaction_to_delete)
        return
    raise HTTPException(status_code=404, detail="Transaction not found")

# ملاحظة: لم نضف التعديل (Update) للتبسيط، حيث أن تعديل الحركات المحاسبية عادة ما يتم عبر "قيد عكسي"
# ولكن يمكن إضافته بنفس طريقة المشروع السابق إذا أردت.
