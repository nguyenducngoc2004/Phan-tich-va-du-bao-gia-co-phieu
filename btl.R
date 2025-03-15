# Cài đặt các thư viện cần thiết
library(sparklyr)
library(dplyr)
library(ggplot2)
library(prophet)
library(plotly)

# Thiết lập Spark
Sys.setenv(SPARK_HOME = "C:/spark-3.5.5-bin-hadoop3")

# Tạo thư mục logs để tránh lỗi log file
dir.create("logs", showWarnings = FALSE)
file.create("logs/log4j.spark.log")

# Cấu hình Spark để bỏ qua lỗi log
config <- spark_config()
config$spark.logConf <- FALSE

sc <- spark_connect(master = "local", spark_home = Sys.getenv("SPARK_HOME"), config = config)

# Kiểm tra kết nối Spark
print(sc)

#  Đọc dữ liệu từ thư mục chứa các tệp CSV
data_path <- "D:/BigData/BTL/StockData"
csv_files <- c("AAPL.csv", "AMZN.csv", "BRK-B.csv", "GOOGL.csv", "META.csv", 
               "MSFT.csv", "NVDA.csv", "QQQ.csv", "SPY.csv", "TSLA.csv", 
               "TSM.csv", "V.csv")

# Đọc dữ liệu vào Spark
stock_data_list <- lapply(csv_files, function(file) {
  dataset_name <- gsub("[-.]", "_", tools::file_path_sans_ext(file))  # Loại bỏ ký tự đặc biệt
  spark_read_csv(sc, name = dataset_name, 
                 path = file.path(data_path, file), 
                 header = TRUE, infer_schema = TRUE)
})

# Kết hợp tất cả dữ liệu thành một bảng duy nhất
stock_data <- Reduce(sdf_bind_rows, stock_data_list)

#  Làm sạch dữ liệu
stock_data <- stock_data %>%
  mutate(
    Close = as.numeric(regexp_replace(CloseLast, "[$, ]", "")),
    Open = as.numeric(regexp_replace(Open, "[$, ]", "")),
    High = as.numeric(regexp_replace(High, "[$, ]", "")),
    Low = as.numeric(regexp_replace(Low, "[$, ]", "")),
    Volume = as.numeric(Volume)
  )

#  Hiển thị dữ liệu trên Spark UI
sdf_register(stock_data, "stock_data_table")
spark_web(sc)  # Mở giao diện web UI của Spark

#  Trực quan hóa dữ liệu với ggplot2
plot_data <- stock_data %>%
  select(Ticker, Date, Close) %>%
  collect()

# Xử lý giá trị thiếu (NA)
plot_data <- plot_data %>% filter(!is.na(Close))

plot_data$Date <- as.Date(plot_data$Date, format = "%m/%d/%Y")

# Kiểm tra dữ liệu trước khi vẽ biểu đồ
print(head(plot_data))

# Vẽ biểu đồ giá cổ phiếu
stock_plot <- ggplot(plot_data, aes(x = Date, y = Close, color = Ticker)) +
  geom_line() +
  theme_minimal() +
  labs(title = "Diễn biến giá cổ phiếu", x = "Ngày", y = "Giá đóng cửa")

print(stock_plot)

#  Tạo thư mục lưu ảnh
save_path <- "D:/BigData/BTL/Du_Doan"
dir.create(save_path, recursive = TRUE, showWarnings = FALSE)

# Lưu biểu đồ giá cổ phiếu tổng quan
ggsave(file.path(save_path, "stock_plot.png"), plot = stock_plot, width = 10, height = 6, dpi = 300)

# Dự báo giá cổ phiếu đến năm 2026 bằng Facebook Prophet
all_tickers <- unique(plot_data$Ticker)

for (company in all_tickers) {
  stock_prophet <- stock_data %>%
    filter(Ticker == company) %>%
    select(Date, Close) %>%
    rename(ds = Date, y = Close) %>%
    collect() %>%
    mutate(ds = as.Date(ds, format = "%m/%d/%Y")) %>%
    na.omit()
  
  print(paste("Đang xử lý:", company))
  print(head(stock_prophet))
  
  if (nrow(stock_prophet) > 50) {
    model <- prophet(stock_prophet, daily.seasonality = TRUE)
    future <- make_future_dataframe(model, periods = 1095)
    forecast <- predict(model, future)
    
    forecast_plot <- plot(model, forecast) + ggtitle(paste("Dự báo giá cổ phiếu", company, "2024-2026"))
    
    print(forecast_plot)
    
    ggsave(file.path(save_path, paste0("forecast_", company, "_2024_2026.png")), 
           plot = forecast_plot, width = 10, height = 6, dpi = 300)
  } else {
    print(paste("Bỏ qua", company, "- Dữ liệu quá ít để dự báo"))
  }
}

#  Tính tỷ suất lợi nhuận của từng cổ phiếu
plot_data <- plot_data %>%
  group_by(Ticker) %>%
  arrange(Date) %>%
  mutate(Daily_Return = (Close / lag(Close) - 1) * 100,
         Cumulative_Return = (Close / first(Close) - 1) * 100) %>%
  ungroup()

# So sánh hiệu suất cổ phiếu
# Biểu đồ lợi nhuận tích lũy
cumulative_plot <- ggplot(plot_data, aes(x = Date, y = Cumulative_Return, color = Ticker)) +
  geom_line() +
  theme_minimal() +
  labs(title = "So sánh lợi nhuận tích lũy của các cổ phiếu",
       x = "Ngày",
       y = "Tỷ suất lợi nhuận (%)")

print(cumulative_plot)
ggsave(file.path(save_path, "cumulative_return.png"), plot = cumulative_plot, width = 10, height = 6, dpi = 300)

# Biểu đồ tỷ suất lợi nhuận hàng ngày (volatility)
daily_return_plot <- ggplot(plot_data, aes(x = Date, y = Daily_Return, color = Ticker)) +
  geom_line(alpha = 0.7) +
  theme_minimal() +
  labs(title = "Tỷ suất lợi nhuận hàng ngày của các cổ phiếu",
       x = "Ngày",
       y = "Tỷ suất lợi nhuận (%)")

print(daily_return_plot)
ggsave(file.path(save_path, "daily_return.png"), plot = daily_return_plot, width = 10, height = 6, dpi = 300)

# Xếp hạng cổ phiếu theo lợi nhuận
stock_performance <- plot_data %>%
  group_by(Ticker) %>%
  summarise(Average_Daily_Return = mean(Daily_Return, na.rm = TRUE),
            Total_Cumulative_Return = last(Cumulative_Return)) %>%
  arrange(desc(Total_Cumulative_Return))

print(stock_performance)
write.csv(stock_performance, file.path(save_path, "stock_performance.csv"), row.names = FALSE)

# Ngắt kết nối Spark
spark_disconnect(sc)
