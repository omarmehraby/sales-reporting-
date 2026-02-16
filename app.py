import streamlit as st
import psycopg2
import pandas as pd

# =========================
# DATABASE CONNECTION
# =========================
conn = psycopg2.connect(
    dbname="sales_reporting_db",
    user="postgres",
    password="Omar#2809",
    host="localhost",
    port="5432"
)

st.set_page_config(page_title="Automated Sales Reporting", layout="wide")

st.title("📊 Automated Sales Reporting System")
st.markdown("Upload sales data, trigger automated reporting, and view business insights.")

# =========================
# CSV UPLOAD
# =========================
st.header("📥 Upload Sales CSV")

uploaded_file = st.file_uploader(
    "Upload CSV file (sale_date, amount, product, category, region)",
    type=["csv"]
)

if uploaded_file is not None:
    df = pd.read_csv(uploaded_file)

    st.subheader("Preview of Uploaded Sales Data")
    st.dataframe(df)

    if st.button("Insert Sales Data & Generate Report"):
        cur = conn.cursor()

        for _, row in df.iterrows():
            cur.execute("""
                INSERT INTO raw_sale (source_id, sale_date, amount, product, category, region)
                SELECT source_id, %s, %s, %s, %s, %s
                FROM data_source
                LIMIT 1;
            """, (
                row["sale_date"],
                row["amount"],
                row["product"],
                row["category"],
                row["region"]
            ))

        conn.commit()
        st.success("Sales data inserted successfully. Automated summary report generated.")

# =========================
# SUMMARY REPORT
# =========================
st.header("📈 Sales Summary Report (Last 14 Days)")

if st.button("View Latest Summary Report"):
    report = pd.read_sql("""
        SELECT
            start_date,
            end_date,
            total_sales,
            total_transactions,
            avg_sale,
            top_category,
            top_region,
            top_product,
            worst_category,
            max_sale,
            sales_trend,
            generated_at
        FROM summary_report
        ORDER BY generated_at DESC
        LIMIT 1
    """, conn)

    if report.empty:
        st.warning("No summary reports available yet.")
    else:
        r = report.iloc[0]

        def safe_text(value, fallback="—"):
            return value if pd.notna(value) else fallback

        def safe_money(value):
            return f"${value:,.2f}" if pd.notna(value) else "—"

        col1, col2, col3 = st.columns(3)
        col1.metric("💰 Total Sales", safe_money(r.total_sales))
        col2.metric("🧾 Transactions", int(r.total_transactions))
        col3.metric("📊 Avg Sale", safe_money(r.avg_sale))

        col4, col5, col6 = st.columns(3)
        col4.metric("🏆 Top Product", safe_text(r.top_product))
        col5.metric("📦 Top Category", safe_text(r.top_category))
        col6.metric("🌍 Top Region", safe_text(r.top_region))

        col7, col8, col9 = st.columns(3)
        col7.metric("⚠️ Weakest Category", safe_text(r.worst_category))
        col8.metric("💎 Highest Sale", safe_money(r.max_sale))
        col9.metric("📈 Sales Trend", safe_text(r.sales_trend))

        st.caption(
            f"Report period: {r.start_date} → {r.end_date} | "
            f"Generated at: {r.generated_at}"
        )

# =========================
# AUTOMATION LOGS
# =========================
st.header("🧠 Automation Logs")

if st.button("View Automation Logs"):
    logs = pd.read_sql("""
        SELECT event_type, message, created_at
        FROM automation_log
        ORDER BY created_at DESC
        LIMIT 10
    """, conn)

    st.dataframe(logs)
