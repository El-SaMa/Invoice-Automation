import csv

def calculate_line_items_total(csv_filename='InvoiceRowData.csv'):
    invoice_totals = {}
    with open(csv_filename, newline='', encoding='utf-8') as csvfile:
        reader = csv.DictReader(csvfile, delimiter=';')  # Ensure delimiter matches your CSV format
        for row in reader:
            try:
                invoice_number = row['InvoiceNumber'].strip()  # Ensure this matches your column name
                line_item_total = int(float(row['Total'].strip()))  # Convert to float and then to integer
                invoice_totals[invoice_number] = invoice_totals.get(invoice_number, 0) + line_item_total
            except KeyError as e:
                print(f"Missing column in CSV: {e}. Check CSV column names.")
            except ValueError:
                print(f"Invalid data for invoice {row.get('InvoiceNumber', 'Unknown')}. Check total values are numeric.")

    return invoice_totals

totals = calculate_line_items_total()
for invoice_number, total in totals.items():
    print(f"Invoice {invoice_number}: Line Items Total = {total}")
