<div align="center">

# AbacatePay Elixir

<img src="https://res.cloudinary.com/dkok1obj5/image/upload/v1767631413/avo_clhmaf.png" width="100%" alt="AbacatePay Open Source"/>

Official **AbacatePay Elixir** SDK to integrate payments via PIX in a simple, secure and fast way.

## Installation

<!-- Add `abacate_pay` to your list of dependencies in `mix.exs`:  -->

Not available yet.

## Features

### Customer Operations

#### Create Customer

Create a new customer in the AbacatePay system.

</div>

```elixir
  customer_data = %{
  name: "John Doe",
  taxId: "123.456.789-00",
  email: "john@example.com",
  cellphone: "+5511999999999"
  }
  
  {:ok, customer} = AbacatePay.Resources.Customer.create(client, customer_data)
```

<div align="center">

#### List Customers

Retrieve a list of all customers.

</div>

```elixir
{:ok, customers} = AbacatePay.Resources.Customer.list(client)
```

<div align="center">

### Billing Operations

#### Create Billing

Create a new billing for a customer.

</div>

```elixir
billing_data = %{
  amount: 1000, # Amount in cents
  customerId: "cust_123", # Customer ID
  methods: ["pix", "credit_card"],
  products: [
    %{
    name: "Product Name",
    amount: 1000,
    quantity: 1
    }
  ]
}

{:ok, billing} = AbacatePay.Resources.Billing.create(client, billing_data)
```

<div align="center">

#### List Billings

Retrieve a list of all billings.

</div>

```elixir
{:ok, billings} = AbacatePay.Resources.Billing.list(client)
```

<div align="center">

### Response Types

#### Customer Response

</div>

```elixir
%Customer{
  id: "cust_123",
  metadata: %{
    name: "John Doe",
    taxId: "123.456.789-00",
    email: "john@example.com",
    cellphone: "+5511999999999"
  }
}
```

<div align="center">

#### Billing Response

</div>

```elixir
%Billing{
  id: "bill_123",
  url: "https://pay.abacatepay.com/...",
  amount: 1000,
  devMode: false,
  status: :pending,
  frequency: :one_time,
  metadata: %{},
  publicId: "pub_123",
  createdAt: "2024-03-20T...",
  updatedAt: "2024-03-20T...",
  methods: [:pix, :credit_card],
  products: [
    %{
    name: "Product Name",
    amount: 1000,
    quantity: 1
    }
  ],
  customer: %{...},
  customerId: "cust_123"
}
```
