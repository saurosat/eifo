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
    const user = new UserAccount(Alpine.store("boConfig"));
    return user.logout().catch((error) => {
        alert(error.message);
    });
}

var loginForm = null;
function getLoginForm(dialog, componentUrl) {
    if(!loginForm) {
        loginForm = new LoginForm(Alpine.store('boConfig'));
        loginForm.setDialog(dialog);
        loginForm.setComponentUrl(componentUrl);
    }
    return loginForm;
}


document.addEventListener('alpine:init', () => {
    Alpine.store('boConfig', {
        on: {},
        timeout: 10000,
        contentType: "application/json;charset=UTF-8",
        baseURL: "http://localhost:8080/rest/s1/foi",
        withCredentials: true,
        defaultToken: Alpine.$persist(sessionToken),
        token: Alpine.$persist(sessionToken).using(sessionStorage),
        storeId: Alpine.$persist(storeId).using(sessionStorage),
        apiKey: Alpine.$persist('').using(sessionStorage),
        loggedIn: Alpine.$persist(false).using(sessionStorage),
        username: Alpine.$persist('').using(sessionStorage),
        userId: Alpine.$persist('').using(sessionStorage),
        partyId: Alpine.$persist('').using(sessionStorage),
        firstName: Alpine.$persist('_NA_').using(sessionStorage),
        lastName: Alpine.$persist('_NA_').using(sessionStorage),
        locale: Alpine.$persist('').using(sessionStorage),
        emailAddress: Alpine.$persist('_NA_').using(sessionStorage),
        contactMechId: Alpine.$persist('').using(sessionStorage),
        contactNumber: Alpine.$persist('').using(sessionStorage),
        postalAddressMap: Alpine.$persist({}).using(sessionStorage),

        isCartLoaded: Alpine.$persist(false),
        paymentsTotal: Alpine.$persist(0),
        orderPromoCodeDetailList: Alpine.$persist([]),
        paymentInfoList: Alpine.$persist([]),
        orderItemList: Alpine.$persist([]),
        orderItemWithChildrenSet: Alpine.$persist([]),
        totalUnpaid: Alpine.$persist(0),
        orderPart: Alpine.$persist({}),
        orderHeader: Alpine.$persist({}),
        productsQuantity: Alpine.$persist(0)
    });


    Alpine.data('cartDialog', (ele, btn) => { 
        if(!window.checkoutForm) {
            window.checkoutForm = new CheckoutForm(Alpine.store('boConfig'));
            window.checkoutForm.loginForm = window.loginForm;
            window.checkoutForm.setDialog(ele);
            window.checkoutForm.setButton(btn);
        }
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