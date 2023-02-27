import streamlit as st
import pandas as pd
from db import create_table, read_data, write_data

def main():
    st.title("My Online Store")

    # Add a form to enter new product data
    form = st.form(key='my_form')
    col1, col2, col3 = form.columns(3)
    with col1:
        product_name = st.text_input("Product Name")
    with col2:
        price = st.number_input("Price")
    with col3:
        quantity = st.number_input("Quantity")
    submitted = form.form_submit_button("Add Product")

    # Write new product data to the 'products' table when the form is submitted
    if submitted:
        new_data = [(product_name, price, quantity)]
        write_data(new_data)

        # Read the last 10 products from the 'products' table again
        data = read_data()

        # Convert the data to a Pandas DataFrame
        df = pd.DataFrame(data, columns=["ID", "Name", "Price", "Quantity"])

        # Set a custom table name
        table_name = "Last 10 Products"

        # Display the data in a table with a custom name
        st.table(df.style.set_caption(table_name))

if __name__ == "__main__":
    main()
