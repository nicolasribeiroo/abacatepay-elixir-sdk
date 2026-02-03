Application.put_env(:abacatepay, :api_url, "http://localhost:4001")

Mimic.copy(AbacatePay.HTTPClient)

ExUnit.configure(exclude: [disabled: true])
ExUnit.start()

Application.ensure_all_started(:bypass)
