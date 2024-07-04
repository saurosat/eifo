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
  
// const categories = {* catJson *};
// const sessionToken = "{* token *}";
// const storeId = "{* storeId *}";
// const currencyUomId = "{* currencyUomId *}"

function getHeaders() {
    let ua = Alpine.store('user')
    let headers = { "Content-Type": "application/json;charset=UTF-8", "store": storeId, "SessionToken": ua.token }
    if(ua.apiKey != null) {
        headers["api_key"] = ua.apiKey;
    }
    return headers;
}
function getReqConfig(method) {
    return { headers: getHeaders(), hostname: "localhost", port: "8080", protocol: "http:", method: method }
}
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
        loggedIn: Alpine.$persist(false).using(sessionStorage),
        username: Alpine.$persist(''),
        // firstName: '',
        // lastName: '',
        // email: '',
        // phone: '',
        token: Alpine.$persist(sessionToken).using(sessionStorage),
        apiKey: Alpine.$persist('').using(sessionStorage),
        userId: Alpine.$persist('').using(sessionStorage),
        firstName: Alpine.$persist('_NA_').using(sessionStorage),
        lastName: Alpine.$persist('_NA_').using(sessionStorage),
        emailAddress: Alpine.$persist('_NA_').using(sessionStorage),
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
                this.loggedIn = false;
            });
        },
        register() {

        }
    });
    Alpine.store('cartInfo', {
        paymentsTotal: Alpine.$persist(0),
        orderPromoCodeDetailList: Alpine.$persist([]),
        paymentInfoList: Alpine.$persist([]),
        orderItemList: Alpine.$persist([]),
        orderItemWithChildrenSet: Alpine.$persist([]),
        totalUnpaid: Alpine.$persist(0),
        orderPart: Alpine.$persist({}),
        orderHeader: Alpine.$persist({}),
        productsQuantity: Alpine.$persist(0),
        open: false,
        assign(data) {
            if(typeof(data.orderItemList) == 'undefined') return;
            for(var i = 0; i < data.orderItemList.length; i++) {
                if(data.orderItemList[i].itemTypeEnumId == 'ItemProduct') {
                    this.productsQuantity += data.orderItemList[i].quantity;
                }
            }
            Object.assign(this, data)
        },
        reset() {
            this.paymentsTotal = 0;
            this.totalUnpaid = 0;
            this.productsQuantity = 0;
            this.orderPromoCodeDetailList = [];
            this.paymentInfoList = [];
            this.orderItemList = [];
            this.orderItemWithChildrenSet = [];
            this.orderPart = {};
            this.orderHeader = {};
        },
        load() {
            ProductService.getCartInfo(getReqConfig("post"))
                    .then((data) => {
                        this.reset();
                        this.assign(data);
                    });
        },
        addProduct(product, quantity = 1) {
            var ua = Alpine.store('user');
            if(ua.loggedIn) {
                ProductService.addProductCart(product, getReqConfig("post"))
                        .then(function (data) {
                            this.reset();
                            this.assign(data);
                        });
            } else {
                let pItemIndex = this.orderItemList.findIndex(item => item.productId === product.productId)
                let pItem = this.orderItemList[pItemIndex]
                if(pItem) {
                    pItem.quantity += quantity;
                    if(pItem.quantity <= 0) {
                        this.orderItemList.splice(pItemIndex, 1)
                    }
                } else {
                    if(quantity > 0) {
                        pItem = {...product, quantity: quantity, currencyUomId: currencyUomId, productStoreId: storeId};
                        this.orderItemList.push(pItem)
                    }
                }
            }
            alert("Added product " + product.pseudoId);
        },
        removeProduct(product, index = -1) {
            let pIndex = index >= 0 ? index : this.orderItemList.findIndex(item => item.productId === product.productId)
            this.orderItemList.splice(pIndex, 1)
        }
    });

    Alpine.data('cartDialog', (dialog) => (new Cart(dialog)));

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
        headers: getHeaders(),
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
                , getReqConfig("post"))
                .then((data) => {
                    let userStore = Alpine.store('user');
                    userStore.setCustomerInfo(data.customerInfo);
                    userStore.token = data.moquiSessionToken;
                    userStore.apiKey = data.apiKey;
                    this.open = false;
                    this.isLoading = false;
                    this.loggedIn = true;
                    Alpine.store('cartInfo').load()
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
