var BO_URL = "";
var GeoService = {
    getCountries: function() { return axios.get(BO_URL + "/rest/s1/foi/geos").then(function (response) { return response.data; }); },
    getRegions: function(geoId) { return axios.get(BO_URL + "/rest/s1/foi/geos/" + geoId + "/regions").then(function (response) { return response.data; }); },
    getLocale: function() { return axios.get(BO_URL + "/rest/s1/foi/locale").then(function (response) { return response.data; }); },
    getTimeZone: function() { return axios.get(BO_URL + "/rest/s1/foi/timeZone").then(function (response) { return response.data; }); }
};

var LoginService = {
    login: function(user, headers) { return axios.post(BO_URL + "/rest/s1/foi/login", user, headers).then(function (response) { return response.data; }); },
    loginFB: function(user, headers) { return axios.post(BO_URL + "/rest/s1/foi/loginFB", user, headers).then(function (response) { return response.data; }); },
    createAccount: function(account, headers) { return axios.post(BO_URL + "/rest/s1/foi/register", account, headers).then(function (response) { return response.data; }); },
    logout: function() { return axios.get(BO_URL + "/rest/s1/foi/logout").then(function (response) { return response.data; }); },
    resetPassword: function(username, headers) { return axios.post(BO_URL + "/rest/s1/foi/resetPassword", username, headers).then(function (response) { return response.data; }); }
};

var CustomerService = {
  getShippingAddresses: function(headers) {
    const t = new Date().getTime();
    return axios.get(BO_URL + "/rest/s1/foi/customer/shippingAddresses?timeStamp=" + t,headers).then(function (response) { return response.data; });
  },
  addShippingAddress: function(address,headers) {
    return axios.put(BO_URL + "/rest/s1/foi/customer/shippingAddresses",address,headers).then(function (response) { return response.data; });
  },
  getPaymentMethods: function(headers) {
    const t = new Date().getTime();
    return axios.get(BO_URL + "/rest/s1/foi/customer/paymentMethods?timeStamp=" + t,headers).then(function (response) { return response.data; });
  },
  addPaymentMethod: function(paymentMethod,headers) {
    return axios.put(BO_URL + "/rest/s1/foi/customer/paymentMethods",paymentMethod,headers).then(function (response) { return response.data; });
  },
  getCustomerOrders: function(headers) {
    return axios.get(BO_URL + "/rest/s1/foi/customer/orders",headers).then(function (response) { return response.data; })
  },
  getCustomerOrderById: function(orderId,headers) {
    return axios.get(BO_URL + "/rest/s1/foi/customer/orders/"+orderId,headers).then(function (response) { return response.data; });
  }, 
  getCustomerInfo: function(headers) {
    return axios.get(BO_URL + "/rest/s1/foi/customer/info").then(function (response) { return response.data; });
  },
  updateCustomerInfo: function(customerInfo,headers) {
    return axios.put(BO_URL + "/rest/s1/foi/customer/updateInfo",customerInfo,headers).then(function (response) { return response.data; });
  },
  updateCustomerPassword: function(customerInfo,headers) {
    return axios.put(BO_URL + "/rest/s1/foi/customer/updatePassword",customerInfo, headers).then(function (response) { return response.data; });
  },
  deletePaymentMethod: function(paymentMethodId,headers) {
    return axios.delete(BO_URL + "/rest/s1/foi/customer/paymentMethods/"+paymentMethodId, headers).then(function (response) { return response.data; });
  },
  deleteShippingAddress: function(contactMechId,contactMechPurposeId,headers) {
    return axios.delete(BO_URL + "/rest/s1/foi/customer/shippingAddresses?contactMechId=" + contactMechId +"&contactMechPurposeId=" + contactMechPurposeId, headers)
        .then(function (response) { return response.data; });
  }
};

var ProductService = {
    getFeaturedProducts: function() {
        return axios.get(BO_URL + "/rest/s1/foi/categories/PopcAllProducts/products").then(function (response) { return response.data.productList; });
    },
    getProductBySearch: function(searchTerm, pageIndex, pageSize, categoryId) {
        var params = "term=" + searchTerm + "&pageIndex=" + pageIndex + "&pageSize=" + pageSize;
        if (categoryId && categoryId.length) params += "&productCategoryId=" + categoryId;
        return axios.get(BO_URL + "/rest/s1/foi/products/search?" + params).then(function (response) { return response.data; });
    },
    getProductsByCategory: function(categoryId, pageIndex, pageSize) {
        var params = "?pageIndex=" + pageIndex + "&pageSize=" + pageSize;
        return axios.get(BO_URL + "/rest/s1/foi/categories/" + categoryId + "/products" + params).then(function (response) { return response.data; });
    },
    getCategoryInfoById: function(categoryId) {
        return axios.get(BO_URL + "/rest/s1/foi/categories/" + categoryId + "/info").then(function (response) { return response.data; });
    },
    getSubCategories: function(categoryId) {
        return axios.get(BO_URL + "/rest/s1/foi/categories/" + categoryId + "/info").then(function (response) { return response.data.subCategoryList; });
    },
    getProduct: function(productId) {
        return axios.get(BO_URL + "/rest/s1/foi/products/" + productId).then(function (response) { return response.data; });
    },
    getProductContent: function(productId, contentTypeEnumId) {
        return axios.get(BO_URL + "/rest/s1/foi/products/content?productId=" + productId + "&productContentTypeEnumId=" + contentTypeEnumId)
            .then(function (response) { return response.data; });
    },
    addProductCart: function(product,headers) {
        return axios.post(BO_URL + "/rest/s1/foi/cart/add",product,headers).then(function (response) { return response.data; });
    },
    getCartInfo: function(headers) {
        const t = new Date().getTime();
        return axios.get(BO_URL + "/rest/s1/foi/cart/info?timeStamp=" + t,headers).then(function (response) { return response.data; });
    },
    addCartBillingShipping: function(data, headers) {
        return axios.post(BO_URL + "/rest/s1/foi/cart/billingShipping",data,headers).then(function (response) { return response.data; });
    },
    getCartShippingOptions: function(headers) {
        return axios.get(BO_URL + "/rest/s1/foi/cart/shippingOptions", headers).then(function (response) { return response.data; });
    },
    placeCartOrder: function(data, headers) {
        return axios.post(BO_URL + "/rest/s1/foi/cart/place",data,headers).then(function (response) { return response.data; });
    },
    updateProductQuantity: function(data, headers) {
        return axios.post(BO_URL + "/rest/s1/foi/cart/updateProductQuantity",data,headers).then(function (response) { return response.data; });
    },
    deleteOrderProduct: function(orderId, orderItemSeqId,headers) {
        return axios.delete(BO_URL + "/rest/s1/foi/cart/deleteOrderItem?orderId="+orderId+"&orderItemSeqId="+orderItemSeqId,headers)
            .then(function (response) { return response.data; });
    },
    addPromoCode: function(data, headers) {
        return axios.post(BO_URL + "/rest/s1/foi/cart/promoCode",data,headers).then(function (response) { return response.data; });
    },
    deletePromoCode: function(data, headers) {
        return axios.delete(BO_URL + "/rest/s1/foi/cart/promoCode", {data: data, headers: headers})
            .then(function (response) { return response.data; });
    }
};

