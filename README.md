# Online Store App with Streamlit

This repository contains an example of an online store application built with the Streamlit library. The app allows users to view a list of products, add new products to the store, and view the 10 most recently added products. The app uses a MySQL database hosted on AWS RDS to store the product data. Also, the Confluent Kafka was use to data streaming. Use Terraform to deploy and manage Confluent infrastructure

## Dependencies
* streamlit
* PyMySQL
* python-dotenv
* Terraform

## Folder Structure
```bash
├── README.md
├── app
│   ├── app.py
│   ├── db.py
│   └── requirements.txt
└── terraform_Confluent
    ├── main.tf
    ├── outputs.tf
    └── terraform.tf
```

## Usage
You need to set up a MySQL server on Amazon RDS
To start the Streamlit app, run:
`cd app && streamlit run app.py`
To deploy the Conluent infrastructure, run:
* `terraform init`
* `terraform apply`

Remember to destroy the Conluent infrastructure if not use, run:
* `terraform destroy`

## Configuration
The app requires a MySQL database to store the product data. You can configure the database credentials by creating a .env file in the root directory of the project with the following environment variables:
```
DB_ENDPOINT=
DB_PORT=
DB_USER=
DB_REGION=
DB_NAME=
DB_PASSWORD=

```
Add the values with your own database credentials.

## License
This code is released under the MIT License.

