using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows.Forms;
using System.Data.SqlClient;

namespace CongCafe
{
    public partial class NVLForm : Form
    {
        DataGridView dgv;
        TextBox txtMaNVL, txtTenNVL, txtDVT;
        private int currentPage = 1;
        private int pageSize = 10;
        private Label lblPageInfo;

        public NVLForm()
        {
            Text = "Quản Lý Nguyên Vật Liệu";
            FormBorderStyle = FormBorderStyle.None;
            SetupUI();
            LoadData();

            ThemeHelper.ApplyTheme(this);
        }

        private void SetupUI()
        {
            Panel pnlTop = new Panel() { Height = 170, Dock = DockStyle.Top };

            pnlTop.Controls.Add(new Label() { Text = "Mã NVL:", Location = new Point(20, 20), AutoSize = true });
            txtMaNVL = new TextBox() { Location = new Point(100, 20), Width = 150 };

            pnlTop.Controls.Add(new Label() { Text = "Tên NVL:", Location = new Point(280, 20), AutoSize = true });
            txtTenNVL = new TextBox() { Location = new Point(360, 20), Width = 200 };

            Button btnThem = new Button() { Text = "Thêm", Location = new Point(600, 18), Width = 100 };
            btnThem.Click += BtnThem_Click;

            Button btnXoa = new Button() { Text = "Xóa", Location = new Point(720, 18), Width = 100 };
            btnXoa.Click += BtnXoa_Click;

            pnlTop.Controls.Add(new Label() { Text = "Đơn Vị:", Location = new Point(20, 70), AutoSize = true });
            txtDVT = new TextBox() { Location = new Point(100, 70), Width = 150 };

            Button btnSua = new Button() { Text = "Sửa", Location = new Point(600, 68), Width = 100 };
            btnSua.Click += BtnSua_Click;

            Button btnPrev = new Button() { Text = "< Trước", Location = new Point(20, 120), Width = 80 };
            btnPrev.Click += (s, e) => { if (currentPage > 1) { currentPage--; LoadData(); } };

            Button btnNext = new Button() { Text = "Tiếp >", Location = new Point(110, 120), Width = 80 };
            btnNext.Click += (s, e) => { currentPage++; LoadData(); };

            lblPageInfo = new Label() { Location = new Point(200, 125), AutoSize = true, Text = "Trang 1" };

            pnlTop.Controls.AddRange(new Control[] { txtMaNVL, txtTenNVL, txtDVT, btnThem, btnSua, btnXoa, btnPrev, btnNext, lblPageInfo });

            dgv = new DataGridView() { Dock = DockStyle.Fill, AllowUserToAddRows = false, ReadOnly = true, SelectionMode = DataGridViewSelectionMode.FullRowSelect };
            dgv.CellClick += (s, e) => {
                if (e.RowIndex >= 0)
                {
                    DataGridViewRow r = dgv.Rows[e.RowIndex];
                    txtMaNVL.Text = r.Cells["MaNVL"].Value.ToString();
                    txtTenNVL.Text = r.Cells["TenNVL"].Value.ToString();
                    txtDVT.Text = r.Cells["DVT"].Value.ToString();
                }
            };

            Controls.Add(dgv);
            Controls.Add(pnlTop);
        }

        private void LoadData()
        {
            string query = $"SELECT * FROM NVL ORDER BY MaNVL OFFSET {(currentPage - 1) * pageSize} ROWS FETCH NEXT {pageSize} ROWS ONLY";
            dgv.DataSource = DatabaseHelper.GetData(query);
            int totalRecords = PaginationHelper.GetTotalRecords("NVL");
            int totalPages = (int)Math.Ceiling((double)totalRecords / pageSize);
            lblPageInfo.Text = $"Trang {currentPage}/{totalPages} ({totalRecords} nguyên vật liệu)";
            if (currentPage >= totalPages) currentPage = totalPages;
        }

        private void BtnThem_Click(object sender, EventArgs e)
        {
            var res = DatabaseHelper.ExecuteProc("sp_ThemNVL", new[] {
                new SqlParameter("@MaNVL", txtMaNVL.Text),
                new SqlParameter("@TenNVL", txtTenNVL.Text),
                new SqlParameter("@DVT", txtDVT.Text)
            });
            MessageBox.Show(res.ThongBao);
            if (res.Check) LoadData();
        }

        private void BtnSua_Click(object sender, EventArgs e)
        {
            var res = DatabaseHelper.ExecuteProc("sp_SuaNVL", new[] {
                new SqlParameter("@MaNVL", txtMaNVL.Text),
                new SqlParameter("@TenNVL", txtTenNVL.Text),
                new SqlParameter("@DVT", txtDVT.Text)
            });
            MessageBox.Show(res.ThongBao);
            if (res.Check) LoadData();
        }

        private void BtnXoa_Click(object sender, EventArgs e)
        {
            if (MessageBox.Show("Bạn có chắc chắn muốn xóa?", "Xác nhận", MessageBoxButtons.YesNo) == DialogResult.Yes)
            {
                try
                {
                    var res = DatabaseHelper.ExecuteProc("sp_XoaNVL", new[] { new SqlParameter("@MaNVL", txtMaNVL.Text) });
                    MessageBox.Show(res.ThongBao);
                    if (res.Check) { txtMaNVL.Clear(); LoadData(); }
                }
                catch (Exception ex)
                {
                    MessageBox.Show("Không thể xóa do đã phát sinh giao dịch nhập hàng.\nLỗi: " + ex.Message);
                }
            }
        }
    }
}
