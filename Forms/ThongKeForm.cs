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

        private void SetupUI()
        {
            Panel pnlTop = new Panel() { Height = 90, Dock = DockStyle.Top };

            pnlTop.Controls.Add(new Label() { Text = "Từ Ngày:", Location = new Point(20, 30), AutoSize = true });
            dtpTuNgay = new DateTimePicker() { Location = new Point(100, 30), Format = DateTimePickerFormat.Short, Width = 150 };

            pnlTop.Controls.Add(new Label() { Text = "Đến Ngày:", Location = new Point(280, 30), AutoSize = true });
            dtpDenNgay = new DateTimePicker() { Location = new Point(370, 30), Format = DateTimePickerFormat.Short, Width = 150 };

            Button btnThongKe = new Button() { Text = "Thống Kê", Location = new Point(560, 27), Width = 120 };
            btnThongKe.Click += BtnThongKe_Click;

            pnlTop.Controls.AddRange(new Control[] { dtpTuNgay, dtpDenNgay, btnThongKe });

            // DataGridView sẽ tự động được làm đẹp nhờ ThemeHelper nên ta chỉ cần khởi tạo cơ bản
            dgv = new DataGridView() { Dock = DockStyle.Fill, AllowUserToAddRows = false, ReadOnly = true };

            Controls.Add(dgv);
            Controls.Add(pnlTop);
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
    }
}