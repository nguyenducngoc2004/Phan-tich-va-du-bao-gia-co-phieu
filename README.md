# 📊 Phân Tích & Dự Báo Giá Cổ Phiếu với Spark & Prophet

## 📌 Giới Thiệu

Dự án này sử dụng **Apache Spark** và **Facebook Prophet** để phân tích, trực quan hóa và dự báo giá cổ phiếu từ nhiều tệp CSV.

-**Ngôn ngữ: R**

-**Công nghệ: Spark, Prophet, ggplot2, dplyr**

## 🎯Tính năng chính:

  #### 📂 Đọc dữ liệu từ nhiều tệp CSV

  #### 🧹 Làm sạch và tiền xử lý dữ liệu

  #### 📈 Trực quan hóa giá cổ phiếu

  #### 🔮 Dự báo giá cổ phiếu đến năm 2026

  #### 📊 So sánh lợi nhuận giữa các cổ phiếu

## 🛠 Cài Đặt

### 1️⃣ Yêu Cầu

-**Apache Spark** (Tải về từ: https://spark.apache.org/downloads.html)

-**R & RStudio**

-**Thư viện R:**
```bash
install.packages(c("sparklyr", "dplyr", "ggplot2", "prophet", "plotly"))
```

### 2️⃣ Cấu Hình Spark

**Đặt biến môi trường Spark:**
```bash
Sys.setenv(SPARK_HOME = "C:/spark-3.5.5-bin-hadoop3")
```

## 🚀 Cách Sử Dụng

### 1️⃣ Kết Nối Spark
```bash
sc <- spark_connect(master = "local", spark_home = Sys.getenv("SPARK_HOME"))
```

### 2️⃣ Đọc Dữ Liệu CSV vào Spark
```bash
stock_data_list <- lapply(csv_files, function(file) {
  dataset_name <- gsub("[-.]", "_", tools::file_path_sans_ext(file))
  spark_read_csv(sc, name = dataset_name, path = file.path(data_path, file), header = TRUE, infer_schema = TRUE)
})
```

### 3️⃣ Trực Quan Hóa Dữ Liệu
```bash
stock_plot <- ggplot(plot_data, aes(x = Date, y = Close, color = Ticker)) +
  geom_line() +
  theme_minimal() +
  labs(title = "Diễn biến giá cổ phiếu", x = "Ngày", y = "Giá đóng cửa")
print(stock_plot)
```

### 4️⃣ Dự Báo Giá Cổ Phiếu với Prophet
```bash
model <- prophet(stock_prophet, daily.seasonality = TRUE)
future <- make_future_dataframe(model, periods = 1095)
forecast <- predict(model, future)
plot(model, forecast) + ggtitle("Dự báo giá cổ phiếu")
```
### 5️⃣ Ngắt Kết Nối Spark
```bash
spark_disconnect(sc)
```
## 📂 Cấu Trúc Dự Án
```bash
📁 D:/BigData/BTL/
│-- 📁 StockData/       # Chứa các tệp CSV
│-- 📁 Du_Doan/         # Lưu kết quả dự báo
│-- 📄 btl.R            # Mã nguồn chính
│-- 📄 README.md        # Tài liệu hướng dẫn
```
## 📢 Lưu Ý

-Đảm bảo **Apache Spark** được cài đặt đúng cách.

-Nếu **Spark UI** không mở được, kiểm tra cổng mặc định của **Spark**.

## 🎯 Mục Tiêu
-✅ Hiểu cách sử dụng **Spark** với **R**

-✅ Phân tích và trực quan hóa dữ liệu cổ phiếu

-✅ Dự báo giá cổ phiếu với **Prophet**

-✅ So sánh hiệu suất cổ phiếu

## 📝 License

© 2025 **Nhóm 4 - Lớp CNTT 1603** 🎓  
🏫 **Trường Đại học Đại Nam** 
