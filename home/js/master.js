const screenWidth = screen.width;
function loadHtml(url, containerEle) {
    if(!url) return;
    fetch(url)
        .then((res) => res.text())
        .then((htmlText) => { containerEle.innerHTML = htmlText;})
        .catch((error) => {alert(error);});
}    
// document.addEventListener('alpine:initialized', () => {
//     alert("initialized");
// });
function logout() {
    LoginService.logout().then(function (data) {
        let userStore = Alpine.store('user');
        userStore.username = '';
        userStore.apiKey = '';
        userStore.token = '';
    });
}
document.addEventListener('alpine:init', () => {
    Alpine.store('user', {
        username: Alpine.$persist(''),
        // firstName: '',
        // lastName: '',
        // email: '',
        // phone: '',
        token: Alpine.$persist(sessionToken).using(sessionStorage),
        apiKey: Alpine.$persist('').using(sessionStorage),
        userId: Alpine.$persist('').using(sessionStorage),
        firstName: Alpine.$persist('').using(sessionStorage),
        emailAddress: Alpine.$persist('').using(sessionStorage),
        locale: Alpine.$persist('').using(sessionStorage),
        setCustomerInfo(data) {
            this.username = data.username;
            this.userId = data.userId;
            this.partyId = data.partyId;
            this.firstName = data.firstName;
            this.lastName = data.lastName;
            this.locale = data.locale;
            this.emailAddress = data.emailAddress;
            this.contactMechId = data.telecomNumber ? data.telecomNumber.contactMechId : "";
            this.contactNumber = data.telecomNumber ? data.telecomNumber.contactNumber : "";
        },
        logout() {
            LoginService.logout().catch(() => {}).finally(() => {
                this.username = '';
                this.apiKey = '';
                this.token = '';
            });
        }
    });
    Alpine.store('cartInfo', {
        "paymentsTotal": 0,
        "orderPromoCodeDetailList": [],
        "paymentInfoList": [],
        "orderItemList": [],
        "orderItemWithChildrenSet": [],
        "totalUnpaid": 0,
        "orderPart": null,
        "orderHeader": null
    });
    Alpine.store('global', {
        carouselImages: [
            "https://images.unsplash.com/photo-1444212477490-ca407925329e?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=1400&q=80",
            "https://images.unsplash.com/photo-1504595403659-9088ce801e29?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=634&q=80",
            "https://images.unsplash.com/photo-1518378188025-22bd89516ee2?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=634&q=80",
            "https://images.unsplash.com/photo-1519150268069-c094cfc0b3c8?ixid=MXwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHw%3D&ixlib=rb-1.2.1&auto=format&fit=crop&w=1378&q=80"
        ],
        loggedIn: false,
        loginDialogOpen: false,
        cartDialogOpen: false,
        headers: { "Content-Type": "application/json;charset=UTF-8", "store": storeId, "SessionToken": Alpine.store('user').token},
    });
    Alpine.data('dropdown', () => ({
        open: false,
        toggle() {
            if (this.open) {
                return this.close();
            }

            this.$refs.button.focus();
            this.open = true;
        },
        close(focusAfter) {
            if (!this.open) return

            this.open = false

            focusAfter && focusAfter.focus()
        }
    }));
    Alpine.data('carouselObj', () => ({
        current: 0,
        images: Alpine.store('global').carouselImages,
        next: function () {
            this.current++;
            if (this.current > this.images.length) this.current = 0;
        },
        prev: function () {
            this.current--;
            if (this.current === -1) this.current = this.images.length; //added one more slide
        }

    }));
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
    Alpine.data('userLogin', () => ({
        username: Alpine.store('user').username,
        password: null,
        open: false,
        errorMsg: null,
        headers: Alpine.store('global').headers,
        isLoading: false,
        login() {
            if (this.username.length < 3 || this.password.length < 3) {
                this.errorMsg = "Username or password is missing";
                alert(this.errorMsg);
                return;
            }
            this.isLoading = true;
            this.errorMsg = null; 
            LoginService.login({ username: this.username, password: this.password }
                , { headers: this.headers, hostname: "localhost", port: 8080, protocol: "http:", method: "post"})
                .then((data) => {
                    let userStore = Alpine.store('user');
                    userStore.setCustomerInfo(data.customerInfo);
                    userStore.token = data.moquiSessionToken;
                    userStore.apiKey = data.apiKey;
                    Alpine.store('global').headers["api_key"] = data.apiKey;
                    this.open = false;
                    this.isLoading = false;
                })
                .catch((error) => {
                    if (!!error.response && !!error.response.headers) {
                        this.headers.moquiSessionToken = error.response.headers.moquisessiontoken;
                        this.token = error.response.headers.moquisessiontoken;
                    }
                    this.errorMsg = error.response.data.errors;
                    this.isLoading = false;
                });
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
