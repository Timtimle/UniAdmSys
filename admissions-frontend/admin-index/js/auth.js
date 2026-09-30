document.addEventListener("DOMContentLoaded", () => {
    const loginBtn = document.getElementById("btnLogin");

    if (loginBtn) {
        loginBtn.addEventListener("click", handleLogin);
    }
});

function handleLogin() {
    const usernameInput = document.getElementById("usernameInput").value.trim();
    const passwordInput = document.getElementById("passwordInput").value.trim();

    // Tài khoản test giả lập cho cán bộ/admin theo yêu cầu
    const validUser = "Nguyễn Nhân Hiếu Nghĩa";
    const validPass = "123456";

    if (!usernameInput || !passwordInput) {
        alert("Vui lòng nhập đầy đủ tài khoản và mật khẩu!");
        return;
    }

    if (usernameInput === validUser && passwordInput === validPass) {
        alert("Đăng nhập thành công! Chào mừng cán bộ Nguyễn Nhân Hiếu Nghĩa.");
        // Chuyển hướng sang trang quản lý hồ sơ
        window.location.href = "index.html";
    } else {
        alert("Sai tài khoản hoặc mật khẩu! (Gợi ý tài khoản: Nguyễn Nhân Hiếu Nghĩa / 123456)");
    }
}