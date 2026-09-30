// Hàm ẩn / hiện khung chat
function toggleChat() {
    var box = document.getElementById("chatBox");
    if (!box) return;
    if (box.style.display === "flex") {
        box.style.display = "none";
    } else {
        box.style.display = "flex";
    }
}

// Hàm gửi tin nhắn và hiển thị phản hồi dạng UI mẫu
function sendMsg() {
    var input = document.getElementById("chatInput");
    if (!input) return;
    var text = input.value.trim();
    if (!text) return;

    var chatBody = document.getElementById("chatBody");
    if (!chatBody) return;

    // 1. Hiển thị tin nhắn người dùng gửi (màu xanh nhẹ bên phải)
    var userMsg = document.createElement("div");
    userMsg.className = "msg user";
    userMsg.style.cssText = "background: #d1e7dd; color: #0f5132; margin-left: auto; margin-bottom: 10px; padding: 10px 14px; border-radius: 10px; max-width: 80%; font-size: 14px; word-break: break-word;";
    userMsg.innerText = text;
    chatBody.appendChild(userMsg);

    input.value = "";
    chatBody.scrollTop = chatBody.scrollHeight;

    // 2. Phản hồi đệm giả lập UI
    setTimeout(function () {
        var botMsg = document.createElement("div");
        botMsg.className = "msg bot";
        botMsg.style.cssText = "background: #e2e3e5; color: #141619; margin-right: auto; margin-bottom: 10px; padding: 10px 14px; border-radius: 10px; max-width: 80%; font-size: 14px; word-break: break-word;";
        botMsg.innerText = 'AI Agent: Cảm ơn bạn đã hỏi về "' + text + '". Hệ thống đang tự động tra cứu dữ liệu...';
        chatBody.appendChild(botMsg);
        chatBody.scrollTop = chatBody.scrollHeight;
    }, 300);
}

// Lắng nghe phím Enter trong ô nhập
document.addEventListener("DOMContentLoaded", function () {
    var input = document.getElementById("chatInput");
    if (input) {
        input.addEventListener("keypress", function (e) {
            if (e.key === "Enter") {
                sendMsg();
            }
        });
    }
});