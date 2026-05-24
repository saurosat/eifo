local l10n = {
    del_confirm_en = "Are you sure to delete this record?",
    del_confirm_vi = "Bạn có chắc chắn muốn xóa bản ghi này?",
    del_confirm_cn = "您确定要删除此记录吗？",
    login_failed_en = "Login failed. Please check your username and password.",
    login_failed_vi = "Đăng nhập thất bại. Vui lòng kiểm tra lại tên đăng nhập và mật khẩu.",
    login_failed_cn = "登录失败。请检查您的用户名和密码。",
    session_expired_en = "Your session has expired. Please login again.",
    session_expired_vi = "Phiên làm việc của bạn đã hết hạn. Vui lòng đăng nhập lại.",
    session_expired_cn = "您的会话已过期。请重新登录。"   
}
local _mt = function (self, key)
    local lang = ngx.var.lang or "en"
    return rawget(self, key.."_"..lang)
end
setmetatable(l10n, {__index = _mt})
return l10n