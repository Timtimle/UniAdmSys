function mockLogin(email, password) {
    return new Promise((resolve, reject) => {
        setTimeout(() => {
            if (email && password.length >= 6) {
                const user = { email: email, name: email.split('@')[0] };
                localStorage.setItem("userToken", "fake-token-jwt-12345");
                localStorage.setItem("currentUser", JSON.stringify(user));
                resolve({ success: true, user });
            } else {
                reject("Mật khẩu phải từ 6 ký tự trở lên!");
            }
        }, 400);
    });
}

function mockSubmitApplication(data) {
    return new Promise((resolve) => {
        setTimeout(() => {
            data.status = "Chờ duyệt"; // Trạng thái mặc định
            data.submittedAt = new Date().toLocaleDateString("vi-VN");
            localStorage.setItem("myApplication", JSON.stringify(data));
            resolve({ success: true, message: "Nộp hồ sơ thành công!" });
        }, 500);
    });
}

function mockGetApplication() {
    const data = localStorage.getItem("myApplication");
    return data ? JSON.parse(data) : null;
}
// Hàm tự động kiểm tra và xử lý nút Đăng nhập / Đăng xuất trên Menu
function checkAuthStatus() {
    var currentUser = localStorage.getItem("currentUser"); // Hoặc key bạn lưu khi đăng nhập thành công
    var nav = document.querySelector("header nav");

    if (!nav) return;

    if (currentUser) {
        // Tìm thẻ a Đăng nhập và đổi thành Đăng xuất
        var loginLink = nav.querySelector('a[href="login.html"]');
        if (loginLink) {
            loginLink.innerText = "Đăng Xuất";
            loginLink.href = "javascript:void(0)";
            loginLink.onclick = function () {
                if (confirm("Bạn có chắc chắn muốn đăng xuất không?")) {
                    localStorage.removeItem("currentUser"); // Xóa trạng thái đăng nhập
                    alert("Đã đăng xuất thành công!");
                    window.location.href = "login.html";
                }
            };
        }
    }
}

// Tự động chạy khi trang web tải xong
document.addEventListener("DOMContentLoaded", checkAuthStatus);