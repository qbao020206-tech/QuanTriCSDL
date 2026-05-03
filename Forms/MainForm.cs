using System;
using System.Collections.Generic;
using System.Drawing;
using System.Windows.Forms;

namespace CongCafe
{
    /// <summary>
    /// MainForm: Sidebar navigation + modern flat design
    /// </summary>
    public partial class MainForm : Form
    {
        private Panel sidebarPanel;
        private Panel contentPanel;
        private const int SIDEBAR_WIDTH = 250;

        private Dictionary<Button, Form> menuForms = new Dictionary<Button, Form>();

        public MainForm()
        {
            Text = $"Cộng Cà Phê - {GlobalState.Username}";
            Size = new Size(1200, 700);
            StartPosition = FormStartPosition.CenterScreen;
            WindowState = FormWindowState.Maximized;
            BackColor = ThemeHelper.CongBeige;

            // ===== TOP HEADER BAR =====
            Panel headerPanel = new Panel
            {
                Dock = DockStyle.Top,
                Height = 60,
                BackColor = ThemeHelper.CongGreen
            };

            // Title
            Label lblHeader = new Label
            {
                Text = "☕ Hệ Thống Quản Lý Cộng Cà Phê",
                Location = new Point(20, 15),
                Size = new Size(600, 30),
                Font = new Font("Segoe UI", 14, FontStyle.Bold),
                ForeColor = Color.White,
                AutoSize = false
            };

            // User info & Logout
            Label lblUser = new Label
            {
                Text = $"👤 {GlobalState.Username}",
                Location = new Point(900, 15),
                Size = new Size(150, 30),
                Font = new Font("Segoe UI", 10),
                ForeColor = Color.White,
                TextAlign = ContentAlignment.MiddleRight,
                AutoSize = false
            };

            Button btnLogout = new Button
            {
                Text = "Đăng Xuất",
                Location = new Point(1060, 15),
                Size = new Size(80, 30),
                Font = new Font("Segoe UI", 9, FontStyle.Bold),
                ForeColor = Color.White,
                BackColor = Color.FromArgb(200, 50, 50),
                FlatStyle = FlatStyle.Flat,
                FlatAppearance = { BorderSize = 0 }
            };
            btnLogout.Click += (s, e) =>
            {
                this.Close();
                Application.Exit();
            };

            headerPanel.Controls.AddRange(new Control[] { lblHeader, lblUser, btnLogout });

            // ===== SIDEBAR =====
            sidebarPanel = new Panel
            {
                Dock = DockStyle.Left,
                Width = SIDEBAR_WIDTH,
                BackColor = Color.FromArgb(245, 245, 240),
                AutoScroll = true
            };

            // Sidebar title
            Label lblSidebarTitle = new Label
            {
                Text = "📋 Menu",
                Location = new Point(10, 15),
                Size = new Size(220, 30),
                Font = new Font("Segoe UI", 11, FontStyle.Bold),
                ForeColor = ThemeHelper.CongBrown,
                AutoSize = false
            };
            sidebarPanel.Controls.Add(lblSidebarTitle);

            // Menu items
            int yPos = 60;
            CreateSidebarMenuItem(sidebarPanel, "👥 Khách Hàng", yPos, new KhachHangForm());
            yPos += 50;
            CreateSidebarMenuItem(sidebarPanel, "🛒 Bán Hàng", yPos, new BanHangForm());
            yPos += 50;
            CreateSidebarMenuItem(sidebarPanel, "📊 Thống Kê", yPos, new ThongKeForm());
            yPos += 50;
            CreateSidebarMenuItem(sidebarPanel, "📦 Sản Phẩm", yPos, new SanPhamForm());
            yPos += 50;

            // Manager only items
            if (GlobalState.IsManager)
            {
                Label lblManagerSection = new Label
                {
                    Text = "⚙️ Quản Lý",
                    Location = new Point(10, yPos),
                    Size = new Size(220, 25),
                    Font = new Font("Segoe UI", 10, FontStyle.Bold),
                    ForeColor = ThemeHelper.CongGreen,
                    AutoSize = false
                };
                sidebarPanel.Controls.Add(lblManagerSection);
                yPos += 35;

                CreateSidebarMenuItem(sidebarPanel, "📥 Nhập Hàng", yPos, new NhapHangForm());
                yPos += 50;
                CreateSidebarMenuItem(sidebarPanel, "🔧 Nguyên Vật Liệu", yPos, new NVLForm());
                yPos += 50;
                CreateSidebarMenuItem(sidebarPanel, "🏭 Nhà Cung Cấp", yPos, new NCCForm());
                yPos += 50;
                CreateSidebarMenuItem(sidebarPanel, "👨‍💼 Nhân Viên", yPos, new NhanVienForm());
            }

            // ===== CONTENT PANEL =====
            contentPanel = new Panel
            {
                Dock = DockStyle.Fill,
                BackColor = ThemeHelper.CongBeige,
                Padding = new Padding(12) // prevent child forms from being drawn under the sidebar
            };

            // Welcome label
            Label lblWelcome = new Label
            {
                Text = $"👋 Chào mừng, {GlobalState.Username}!",
                Location = new Point(50, 80),
                Size = new Size(600, 50),
                Font = new Font("Segoe UI", 18, FontStyle.Bold),
                ForeColor = ThemeHelper.CongBrown,
                AutoSize = false
            };
            contentPanel.Controls.Add(lblWelcome);

            // Create TableLayoutPanel to guarantee fixed sidebar and content area (no overlap)
            TableLayoutPanel layout = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                ColumnCount = 2,
                RowCount = 1
            };
            layout.ColumnStyles.Clear();
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Absolute, SIDEBAR_WIDTH)); // fixed sidebar width
            layout.ColumnStyles.Add(new ColumnStyle(SizeType.Percent, 100F)); // content fills rest
            layout.RowStyles.Add(new RowStyle(SizeType.Percent, 100F));

            // Sidebar should fill its cell
            sidebarPanel.Dock = DockStyle.Fill;
            contentPanel.Dock = DockStyle.Fill;

            layout.Controls.Add(sidebarPanel, 0, 0);
            layout.Controls.Add(contentPanel, 1, 0);

            // Create root table to guarantee header reserves space and main layout below it
            TableLayoutPanel root = new TableLayoutPanel
            {
                Dock = DockStyle.Fill,
                RowCount = 2,
                ColumnCount = 1
            };
            root.RowStyles.Clear();
            root.RowStyles.Add(new RowStyle(SizeType.Absolute, headerPanel.Height)); // fixed header height
            root.RowStyles.Add(new RowStyle(SizeType.Percent, 100F)); // main layout fills remaining

            // Ensure header fills its cell for consistent look
            headerPanel.Dock = DockStyle.Fill;
            layout.Dock = DockStyle.Fill;

            root.Controls.Add(headerPanel, 0, 0);
            root.Controls.Add(layout, 0, 1);

            Controls.Add(root);
        }

        private void CreateSidebarMenuItem(Panel sidebar, string text, int yPos, Form targetForm)
        {
            Button btn = new Button
            {
                Text = text,
                Location = new Point(5, yPos),
                Size = new Size(SIDEBAR_WIDTH - 20, 40),
                Font = new Font("Segoe UI", 10, FontStyle.Regular),
                ForeColor = ThemeHelper.CongBrown,
                BackColor = Color.White,
                FlatStyle = FlatStyle.Flat,
                FlatAppearance = { BorderSize = 1, BorderColor = Color.LightGray },
                TextAlign = ContentAlignment.MiddleLeft,
                Padding = new Padding(10, 0, 0, 0),
                Cursor = Cursors.Hand
            };

            // Store initial form instance in dictionary
            menuForms[btn] = targetForm;

            btn.Click += (s, e) =>
            {
                // Close and remove existing controls in contentPanel
                foreach (Control ctrl in contentPanel.Controls)
                {
                    if (ctrl is Form frm)
                    {
                        try { frm.Close(); } catch { }
                    }
                }
                contentPanel.Controls.Clear();

                // Retrieve the (possibly replaced) target form from the dictionary
                Form formToShow = menuForms.ContainsKey(btn) ? menuForms[btn] : null;

                // If the stored form was disposed (user closed it), create a fresh instance dynamically
                if (formToShow == null || formToShow.IsDisposed)
                {
                    Type t = targetForm.GetType();
                    formToShow = (Form)Activator.CreateInstance(t);
                    menuForms[btn] = formToShow;
                }

                // Prepare and show the form inside contentPanel
                formToShow.TopLevel = false;
                formToShow.FormBorderStyle = FormBorderStyle.None;
                formToShow.Dock = DockStyle.Fill;
                contentPanel.Controls.Add(formToShow);
                formToShow.Show();

                // Highlight active button
                foreach (var kvp in menuForms)
                {
                    bool isActive = kvp.Value == formToShow && kvp.Value.Parent == contentPanel;
                    kvp.Key.BackColor = isActive ? ThemeHelper.CongGreen : Color.White;
                    kvp.Key.ForeColor = isActive ? Color.White : ThemeHelper.CongBrown;
                }
            };

            btn.MouseEnter += (s, e) =>
            {
                Form formRef = menuForms.ContainsKey(btn) ? menuForms[btn] : null;
                if (formRef == null || formRef.Parent != contentPanel)
                    btn.BackColor = Color.FromArgb(230, 230, 220);
            };

            btn.MouseLeave += (s, e) =>
            {
                Form formRef = menuForms.ContainsKey(btn) ? menuForms[btn] : null;
                if (formRef == null || formRef.Parent != contentPanel)
                    btn.BackColor = Color.White;
            };

            sidebar.Controls.Add(btn);
        }
    }
}
