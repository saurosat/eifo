const screenWidth = screen.width;
const jsonContentType = "application/json;charset=UTF-8";


String.prototype.hashCode = function() {
    var hash = 0,
      i, chr;
    if (this.length === 0) return hash;
    for (i = 0; i < this.length; i++) {
      chr = this.charCodeAt(i);
      hash = ((hash << 5) - hash) + chr;
      hash |= 0; // Convert to 32bit integer
    }
    return hash;
}

// document.addEventListener('alpine:initialized', () => {
//     alert("initialized");
// });
function logout() {
    return Alpine.store("user").logout();
}

document.addEventListener('alpine:init', () => {
    Alpine.store('boConfig', {
        token: Alpine.$persist(sessionToken).using(sessionStorage),
        store: Alpine.$persist(storeId).using(sessionStorage),
        apiKey: Alpine.$persist('').using(sessionStorage),
        loggedIn: Alpine.$persist(false).using(sessionStorage)
    });
    BOClient.setMetaObject(Alpine.store('boConfig'));

    const userAccount = new UserAccount();
    userAccount.username = Alpine.$persist('').using(sessionStorage);
    userAccount.userId = Alpine.$persist('').using(sessionStorage);
    userAccount.partyId = Alpine.$persist('').using(sessionStorage);
    userAccount.firstName = Alpine.$persist('_NA_').using(sessionStorage);
    userAccount.lastName = Alpine.$persist('_NA_').using(sessionStorage);
    userAccount.locale = Alpine.$persist('').using(sessionStorage);
    userAccount.emailAddress = Alpine.$persist('_NA_').using(sessionStorage);
    userAccount.contactMechId = Alpine.$persist('').using(sessionStorage);
    userAccount.contactNumber = Alpine.$persist('').using(sessionStorage);
    userAccount.postalAddressMap = Alpine.$persist({}).using(sessionStorage);

    Alpine.store('user', userAccount);

    const cartInfo = new Cart();
    cartInfo.paymentsTotal = Alpine.$persist(0);
    cartInfo.orderPromoCodeDetailList = Alpine.$persist([]);
    cartInfo.paymentInfoList = Alpine.$persist([]);
    cartInfo.orderItemList = Alpine.$persist([]);
    cartInfo.orderItemWithChildrenSet = Alpine.$persist([]);
    cartInfo.totalUnpaid = Alpine.$persist(0);
    cartInfo.orderPart = Alpine.$persist({});
    cartInfo.orderHeader = Alpine.$persist({});
    cartInfo.productsQuantity = Alpine.$persist(0);
    Alpine.store('cartInfo', cartInfo);

    window.loginForm = new LoginForm(Alpine.store("user"));
    Alpine.data('userLogin', (dialog, componentUrl) => {
        window.loginForm.setDialog(dialog);
        window.loginForm.setComponentUrl(componentUrl);
        return loginForm;
    });

    window.checkoutForm = new CheckoutForm(Alpine.store('cartInfo'));
    window.checkoutForm.loginForm = loginForm;
    window.checkoutForm.addressMap = userAccount.postalAddressMap;
    Alpine.data('cartDialog', (ele, btn) => { 
        window.checkoutForm.setDialog(ele);
        window.checkoutForm.setButton(btn);
        return window.checkoutForm; 
    });

    Alpine.data('searchObj', () => ({
        cat: 'All',
        query: '',
        adjustSize() {
            const sel = this.$refs.panelSelect;
            sel.style.width = (sel.options[sel.selectedIndex].text.length + 5) + 'ex'
            const maxWidth = screenWidth / 3
            if (sel.clientWidth > maxWidth) {
                sel.style.width = maxWidth + "px";
            }
        },
        search() {

        }
    }));

    Alpine.data('Promotion', () => ({
        discount: "",
        title: "",
        shortDesc: "",
        actionText: "",
        actionLink: "",
        set(promotionObj) {
            this.discount = promotionObj.discount;
            this.title = promotionObj.title;
            this.shortDesc = promotionObj.shortDesc;
            this.actionText = promotionObj.actionText;
            this.actionLink = promotionObj.actionLink;
        }
    }));
});