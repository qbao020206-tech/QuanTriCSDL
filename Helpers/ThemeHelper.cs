using System.Drawing;
using System.Windows.Forms;

namespace CongCafe
{
    public static class ThemeHelper
    {
        // 1. Định nghĩa Bảng màu chuẩn Cộng Cà Phê
        public static Color CongGreen = Color.FromArgb(75, 83, 32);     // Xanh lính (Chủ đạo, Header)
        public static Color CongBeige = Color.FromArgb(238, 232, 213);    // Vàng bao cấp (Nền Form)
        public static Color CongBrown = Color.FromArgb(78, 52, 46);     // Nâu gỗ (Chữ, Viền)
        public static Color CongRed = Color.FromArgb(178, 34, 34);      // Đỏ đô (Nút Xóa/Hủy)
        public static Color CongHighlight = Color.FromArgb(107, 112, 92); // Xanh lính nhạt (Hover)

        // 2. Hàm nhuộm màu tự động
        public static void ApplyTheme(Control control)
        {
            // Đổi màu nền chính của Form
            if (control is Form frm)
            {
                frm.BackColor = CongBeige;
                frm.Font = new Font("Segoe UI", 10F, FontStyle.Regular);
            }

            foreach (Control c in control.Controls)
            {
                StyleControl(c);
                // Đệ quy nếu control chứa các control con (như Panel, GroupBox)
                if (c.HasChildren)
                {
                    ApplyTheme(c);
                }
            }
        }

        // 3. Logic xử lý cho từng loại Control
        private static void StyleControl(Control c)
        {
            if (c is Panel pnl)
            {
                pnl.BackColor = CongBeige; // Hoặc trong suốt
            }
            else if (c is Label lbl)
            {
                lbl.ForeColor = CongBrown;
                lbl.Font = new Font("Segoe UI", 10F, FontStyle.Bold);
            }
            else if (c is Button btn)
            {
                // Làm phẳng nút bấm (Flat Design)
                btn.FlatStyle = FlatStyle.Flat;
                btn.FlatAppearance.BorderSize = 0;
                btn.Font = new Font("Segoe UI", 10F, FontStyle.Bold);
                btn.ForeColor = Color.White;
                btn.Cursor = Cursors.Hand;

                // Nút Xóa/Hủy thì dùng màu Đỏ, còn lại dùng Xanh lính
                if (btn.Text.ToLower().Contains("xóa") || btn.Text.ToLower().Contains("hủy"))
                {
                    btn.BackColor = CongRed;
                    btn.FlatAppearance.MouseOverBackColor = Color.IndianRed;
                }
                else
                {
                    btn.BackColor = CongGreen;
                    btn.FlatAppearance.MouseOverBackColor = CongHighlight;
                }
            }
            else if (c is TextBox txt)
            {
                txt.BorderStyle = BorderStyle.FixedSingle;
                txt.BackColor = Color.White;
                txt.ForeColor = CongBrown;
                txt.Font = new Font("Segoe UI", 11F, FontStyle.Regular);
                // Ép chiều cao tối thiểu để chữ không bị cắt phần đuôi
                txt.MinimumSize = new Size(0, 28);
            }
            else if (c is ComboBox cb)
            {
                cb.Font = new Font("Segoe UI", 11F, FontStyle.Regular);
                cb.ForeColor = CongBrown;
                cb.FlatStyle = FlatStyle.Flat;
            }
            else if (c is DateTimePicker dtp)
            {
                dtp.Font = new Font("Segoe UI", 11F, FontStyle.Regular);
                dtp.CalendarForeColor = CongBrown;
            }
            else if (c is DataGridView dgv)
            {
                // 1. CHỈNH KÍCH CỠ TABLE (Yêu cầu của bạn)
                // Ép các cột tự động giãn đều để lấp đầy khoảng trống của table
                dgv.AutoSizeColumnsMode = DataGridViewAutoSizeColumnsMode.Fill;
                // Tăng chiều cao của mỗi dòng (mặc định của WinForms hơi lùn và rít)
                dgv.RowTemplate.Height = 35;
                // Vô hiệu hóa cột mũi tên trống ở lề trái
                dgv.RowHeadersVisible = false;

                // 2. CHỈNH GIAO DIỆN MÀU SẮC
                dgv.EnableHeadersVisualStyles = false;
                dgv.BorderStyle = BorderStyle.None;
                dgv.BackgroundColor = CongBeige; // Nền vàng nhạt
                dgv.GridColor = CongHighlight;

                // Style cho thanh Tiêu đề cột (Header)
                dgv.ColumnHeadersDefaultCellStyle.BackColor = CongGreen;
                dgv.ColumnHeadersDefaultCellStyle.ForeColor = Color.White;
                dgv.ColumnHeadersDefaultCellStyle.Font = new Font("Segoe UI", 11F, FontStyle.Bold);
                dgv.ColumnHeadersHeight = 40; // Chiều cao thanh tiêu đề

                // Style cho các dòng dữ liệu
                dgv.DefaultCellStyle.BackColor = Color.White;
                dgv.DefaultCellStyle.ForeColor = CongBrown;
                dgv.DefaultCellStyle.Font = new Font("Segoe UI", 10F, FontStyle.Regular);
                dgv.DefaultCellStyle.SelectionBackColor = CongHighlight;
                dgv.DefaultCellStyle.SelectionForeColor = Color.White;

                // Hiệu ứng sọc dưa (Dòng chẵn/lẻ màu khác nhau cho dễ nhìn)
                dgv.AlternatingRowsDefaultCellStyle.BackColor = Color.FromArgb(245, 245, 240);
            }
        }
    }
}