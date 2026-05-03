using System;
using System.Data;
using System.Data.SqlClient;
using System.Drawing;
using System.Windows.Forms;

namespace CongCafe // Hãy đảm bảo namespace này trùng với project của bạn nhé
{
    public partial class ThongKeForm : Form
    {
        DateTimePicker dtpTuNgay, dtpDenNgay;
        DataGridView dgv;

        public ThongKeForm()
        {
            Text = "Thống Kê Doanh Thu";
            FormBorderStyle = FormBorderStyle.None;

            // 1. Tạo các thành phần giao diện
            SetupUI();

            // 2. Nhuộm màu đồng bộ theo phong cách Cộng Cà Phê
            ThemeHelper.ApplyTheme(this);
        }

        private FlowLayoutPanel pnlSummary;

        private void SetupUI()
        {
            // Top filters panel
            Panel pnlTop = new Panel() { Height = 90, Dock = DockStyle.Top };

            pnlTop.Controls.Add(new Label() { Text = "Từ Ngày:", Location = new Point(20, 30), AutoSize = true });
            dtpTuNgay = new DateTimePicker() { Location = new Point(100, 30), Format = DateTimePickerFormat.Short, Width = 150 };

            pnlTop.Controls.Add(new Label() { Text = "Đến Ngày:", Location = new Point(280, 30), AutoSize = true });
            dtpDenNgay = new DateTimePicker() { Location = new Point(370, 30), Format = DateTimePickerFormat.Short, Width = 150 };

            Button btnThongKe = new Button() { Text = "Thống Kê", Location = new Point(560, 27), Width = 120 };
            btnThongKe.Click += BtnThongKe_Click;

            pnlTop.Controls.AddRange(new Control[] { dtpTuNgay, dtpDenNgay, btnThongKe });

            // Summary cards panel (under filters)
            pnlSummary = new FlowLayoutPanel()
            {
                Height = 100,
                Dock = DockStyle.Top,
                Padding = new Padding(10),
                AutoSize = false
            };

            // Create three summary cards
            pnlSummary.Controls.Add(CreateSummaryCard("Tổng Doanh Thu", "0 đ"));
            pnlSummary.Controls.Add(CreateSummaryCard("Tổng Đơn Hàng", "0"));
            pnlSummary.Controls.Add(CreateSummaryCard("Sản Phẩm Bán Chạy", "-"));

            // DataGridView sẽ tự động được làm đẹp nhờ ThemeHelper nên ta chỉ cần khởi tạo cơ bản
            dgv = new DataGridView() { Dock = DockStyle.Fill, AllowUserToAddRows = false, ReadOnly = true };

            // Important: add panels in order so docking behaves correctly
            Controls.Add(dgv);
            Controls.Add(pnlSummary);
            Controls.Add(pnlTop);
        }

        private Panel CreateSummaryCard(string title, string value)
        {
            Panel card = new Panel()
            {
                Width = 300,
                Height = 80,
                BackColor = Color.White,
                Margin = new Padding(10),
                Padding = new Padding(10)
            };

            Label lblTitle = new Label()
            {
                Text = title,
                Font = new Font("Segoe UI", 9, FontStyle.Regular),
                ForeColor = ThemeHelper.CongBrown,
                Dock = DockStyle.Top,
                Height = 20
            };

            Label lblValue = new Label()
            {
                Text = value,
                Font = new Font("Segoe UI", 14, FontStyle.Bold),
                ForeColor = ThemeHelper.CongGreen,
                Dock = DockStyle.Fill,
                TextAlign = ContentAlignment.MiddleLeft
            };

            card.Controls.Add(lblValue);
            card.Controls.Add(lblTitle);

            // store label for updating
            card.Tag = lblValue;

            return card;
        }

        private void BtnThongKe_Click(object sender, EventArgs e)
        {
            // Kiểm tra logic thời gian cơ bản trước khi gọi CSDL
            if (dtpTuNgay.Value.Date > dtpDenNgay.Value.Date)
            {
                MessageBox.Show("Ngày bắt đầu không được lớn hơn ngày kết thúc!", "Lỗi", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                return;
            }

            try
            {
                using (SqlConnection conn = new SqlConnection(GlobalState.GetConnectionString()))
                {
                    using (SqlCommand cmd = new SqlCommand("sp_ThongKeDoanhThu_TungSanPham", conn))
                    {
                        cmd.CommandType = CommandType.StoredProcedure;

                        // Truyền tham số đầu vào
                        cmd.Parameters.AddWithValue("@TuNgay", dtpTuNgay.Value.Date);
                        // AddDays(1).AddTicks(-1) để lấy đến tận 23:59:59 của ngày kết thúc
                        cmd.Parameters.AddWithValue("@DenNgay", dtpDenNgay.Value.Date.AddDays(1).AddTicks(-1));

                        // Cấu hình tham số đầu ra (OUTPUT) bắt buộc
                        SqlParameter pThongBao = new SqlParameter("@thongBao", SqlDbType.NVarChar, 500) { Direction = ParameterDirection.Output };
                        SqlParameter pCheck = new SqlParameter("@check", SqlDbType.Bit) { Direction = ParameterDirection.Output };
                        cmd.Parameters.Add(pThongBao);
                        cmd.Parameters.Add(pCheck);

                        DataTable dt = new DataTable();
                        using (SqlDataAdapter da = new SqlDataAdapter(cmd))
                        {
                            da.Fill(dt); // Thực thi proc và đổ dữ liệu vào bảng
                        }

                        // Hiển thị kết quả lên DataGridView
                        dgv.DataSource = dt;

                        // Update summary cards
                        UpdateSummaryFromData(dt);

                        // Đọc giá trị Output trả về từ proc
                        bool check = pCheck.Value != DBNull.Value && Convert.ToBoolean(pCheck.Value);
                        string thongBao = pThongBao.Value?.ToString() ?? "";

                        // Nếu check = 0 (Lỗi) hoặc không có dòng dữ liệu nào được trả ra
                        if (!check || dt.Rows.Count == 0)
                        {
                            MessageBox.Show(thongBao, "Thông báo", MessageBoxButtons.OK, MessageBoxIcon.Information);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                MessageBox.Show("Lỗi khi tải dữ liệu thống kê: " + ex.Message, "Lỗi Hệ Thống", MessageBoxButtons.OK, MessageBoxIcon.Error);
            }
        }

        private void UpdateSummaryFromData(DataTable dt)
        {
            try
            {
                decimal totalRevenue = 0;
                int totalOrders = 0;
                string topProduct = "-";

                if (dt.Rows.Count > 0)
                {
                    // Assume stored proc returns columns: MaSP, TenSP, SoLuong, DoanhThu (adjust as per SQL)
                    foreach (DataRow r in dt.Rows)
                    {
                        if (dt.Columns.Contains("DoanhThu"))
                        {
                            decimal val = 0;
                            decimal.TryParse(r["DoanhThu"].ToString(), out val);
                            totalRevenue += val;
                        }

                        if (dt.Columns.Contains("SoLuong"))
                        {
                            int q = 0;
                            int.TryParse(r["SoLuong"].ToString(), out q);
                            totalOrders += q;
                        }
                    }

                    // Top product by SoLuong
                    if (dt.Columns.Contains("TenSP") && dt.Columns.Contains("SoLuong"))
                    {
                        DataRow[] rows = dt.Select("1=1");
                        int bestQty = -1;
                        foreach (var r in rows)
                        {
                            int q = 0;
                            int.TryParse(r["SoLuong"].ToString(), out q);
                            if (q > bestQty)
                            {
                                bestQty = q;
                                topProduct = r["TenSP"].ToString();
                            }
                        }
                    }
                }

                // Update labels in summary cards
                foreach (Control c in pnlSummary.Controls)
                {
                    if (c is Panel card && card.Tag is Label lbl)
                    {
                        if (card.Controls[1] is Label title)
                        {
                            string t = title.Text;
                            if (t.Contains("Doanh Thu")) lbl.Text = string.Format("{0:N0} đ", totalRevenue);
                            else if (t.Contains("Đơn Hàng")) lbl.Text = totalOrders.ToString();
                            else if (t.Contains("Bán Chạy")) lbl.Text = topProduct;
                        }
                    }
                }
            }
            catch { /* non-critical */ }
        }
    }
}