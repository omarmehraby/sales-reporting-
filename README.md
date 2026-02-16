# Sales Reporting System

## Overview

The Sales Reporting System is a data-driven application designed to manage, analyze, and generate structured sales reports using Python and SQL. This project demonstrates database design, SQL-based analytics, and automated reporting through Python integration. It is structured to showcase practical skills in database systems, data processing, and reporting automation.

The system integrates a relational database schema, SQL reporting logic, a Python application for execution, and sample datasets for demonstration and testing.

---

## Objectives

- Design and implement a structured relational sales database
- Perform data aggregation and analysis using SQL
- Automate reporting workflows using Python
- Demonstrate integration between CSV data and SQL databases
- Maintain clean and modular project structure

---

## Repository Structure

sales-reporting/
│
├── app.py
├── databasecrt.sql
├── codeofsales.sql
├── sales_data_december_2025.csv
├── Project_FinalReport_Sampleoutline (1).docx
├── Screenshot_*.png
└── README.md

---

## File Descriptions

**app.py**  
Main Python application responsible for connecting to the database, executing reporting queries, and displaying results.

**databasecrt.sql**  
SQL script used to create the database schema, including tables, constraints, and relationships.

**codeofsales.sql**  
Contains SQL queries for revenue calculations, aggregation, summaries, and reporting logic.

**sales_data_december_2025.csv**  
Sample dataset used to populate the database and test reporting functionality.

**Project_FinalReport_Sampleoutline (1).docx**  
Supporting documentation outlining the structure of the final report.

**Screenshot Files**  
Images demonstrating application output and report results.

---

## System Architecture

The system follows a three-layer structure:

1. Data Layer  
   A relational SQL database storing structured sales records.

2. Processing Layer  
   A Python application that executes queries and processes data.

3. Reporting Layer  
   Aggregated outputs presented via console or structured summaries.

---

## Installation and Setup

### Prerequisites

- Python 3.8 or higher
- PostgreSQL or compatible SQL database
- pip package manager

### Install Required Packages

If no requirements file is provided, install dependencies manually:

pip install pandas psycopg2 sqlalchemy

Adjust according to the libraries used inside app.py.

---

## Database Setup

1. Open your SQL client (e.g., pgAdmin or psql).
2. Run the schema creation script:

   \i databasecrt.sql

3. Execute reporting or additional logic:

   \i codeofsales.sql

4. Import the CSV dataset into the corresponding table if necessary.

---

## Running the Application

From the root project directory:

python app.py

Ensure database credentials inside app.py are correctly configured before execution.

---

## Example Functionalities

- Total revenue calculation
- Monthly sales summary
- Product-level aggregation
- Customer purchase analysis
- Period-based reporting

---

## Design Considerations

- Relational integrity enforced through SQL constraints
- Separation of schema creation and reporting logic
- Modular structure for maintainability and scalability
- Clear organization for academic or portfolio presentation

---

## Possible Extensions

- Add a web dashboard using Streamlit or Flask
- Implement real-time data ingestion
- Add automated scheduled reporting
- Integrate visualization libraries for analytics
- Include forecasting or predictive modeling

---

## Academic Context

This project demonstrates applied knowledge in:

- Database Systems
- SQL Query Optimization
- Python Data Processing
- Software Architecture
- Reporting Automation

It can serve as a portfolio project or course submission.

---

## License

No license is currently specified. Consider adding an open-source license such as MIT or Apache 2.0 if public reuse is intended.

---

## Author

Omar Mehraby  
Computer Science Student  
Al Akhawayn University
