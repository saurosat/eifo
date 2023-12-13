    var timer; //for the show/hide timeout code
    var currentlyOpenMenu = null;

    const subLan = document.getElementById('language-menu-dropdown-mobile');
    const subSignin = document.getElementById('sign-in-menu-dropdown-mobile');
    const subOrders = document.getElementById('orders-menu-dropdown-mobile');
    const subReturns = document.getElementById('returns-menu-dropdown-mobile');

//hamburger button and dropdown menu code
/////////////////////////////////////////


//
//  MOCKDATA PORTION
//

    // Load mock data
    var mockData = {
        "paymentsTotal": 0,
        "orderPromoCodeDetailList": [],
        "paymentInfoList": [],
        "orderItemList": [
            {
                "orderId": "100001",
                "orderItemSeqId": "01",
                "orderPartSeqId": "01",
                "itemTypeEnumId": "ItemProduct",
                "productId": "DEMO_CMUG",
                "itemDescription": "Coffee Mug",
                "quantity": 1,
                "unitAmount": 6.99,
                "unitListPrice": 9.99,
                "isModifiedPrice": "N",
                "productPriceId": "DEMO_CMUG_CLT",
                "lastUpdatedStamp": 1701832531789,
                "imageUrl": "../../../home/img/DEMO_001.webp"
            },
            {
                "orderId": "100001",
                "orderItemSeqId": "02",
                "orderPartSeqId": "01",
                "itemTypeEnumId": "ItemProduct",
                "productId": "DEMO_BCAP",
                "itemDescription": "Baseball Cap",
                "quantity": 2,
                "unitAmount": 19.99,
                "unitListPrice": 24.99,
                "isModifiedPrice": "Y",
                "productPriceId": "DEMO_BCAP_CLT",
                "lastUpdatedStamp": 1701834187101,
                "imageUrl": "../../../home/img/DEMO_002.webp"
            }
        ],
        "orderItemWithChildrenSet": [],
        "totalUnpaid": 46.97,
        "orderPart": {
            "orderId": "100001",
            "orderPartSeqId": "01",
            "statusId": "OrderOpen",
            "carrierPartyId": "_NA_",
            "shipmentMethodEnumId": "ShMthGround",
            "partTotal": 46.97,
            "priority": 5,
            "lastUpdatedStamp": 1701834187101
        },
        "orderHeader": {
            "orderId": "100001",
            "entryDate": 1701832532059,
            "statusId": "OrderOpen",
            "orderRevision": 1,
            "currencyUomId": "USD",
            "salesChannelEnumId": "ScWeb",
            "visitId": "100001",
            "grandTotal": 46.97,
            "lastUpdatedStamp": 1701834187101
        }
    };


// ProductViewModel
function ProductViewModel(data) {
    var self = this;

    //product summary items
    // self.orderSummaryItems = ko.observableArray([
    //     { label: 'Subtotal', value: '$' + data.totalUnpaid.toFixed(2) },
    //     { label: 'Total Items', value: data.orderItemList.length },
    //     // Add more items based on your data structure
    // ]);
    self.productItemList = ko.observableArray(data.orderItemList);
}


//     function ProductItem(data) {
//     this.orderId = ko.observable(data.orderId);
//     this.orderItemSeqId = ko.observable(data.orderItemSeqId);
//     this.orderPartSeqId = ko.observable(data.orderPartSeqId);
//     this.itemTypeEnumId = ko.observable(data.itemTypeEnumId);
//     // ... other properties
//     this.imgUrl = ko.observable(data.imgUrl);
// }

// function ProductViewModel(data) {
//     this.productItemList = ko.observableArray([]);

//     // Populate product items
//     data.orderItemList.forEach(function (itemData) {
//         this.productItemList.push(new ProductItem(itemData));
//     }, this);
// }


    // OrderViewModel
    function OrderViewModel(data) {
        var self = this;

        //order summary items
        self.orderSummaryItems = ko.observableArray([
            { label: 'Subtotal', value: '$' + data.totalUnpaid.toFixed(2) },
            { label: 'Total Items', value: data.orderItemList.length },
            // Add more items based on your data structure
        ]);

        // Example checkout function
        self.checkout = function () {
            // Your checkout logic here
            console.log('Checkout clicked!');
        };
    }

    // Apply bindings
    var productViewModel = new ProductViewModel(mockData);
    var orderViewModel = new OrderViewModel(mockData);
    ko.applyBindings(productViewModel, document.getElementById("itemSummary"));
    ko.applyBindings(orderViewModel, document.getElementById("orderSummary"));


//
//
//

    document.addEventListener('click', function (event) {
        const hamburgMenu = document.getElementById('hamburg-menu');
        const mobileMenu = document.getElementById('language-menu-mobile');
        const hamburgSpan = document.getElementById('hamburg-span');
        const mobileMenuSub1 = document.getElementById('language-menu-dropdown-mobile-span1');
        const mobileMenuSub12 = document.getElementById('language-menu-dropdown-mobile-span2');
        const mobileMenuSub13 = document.getElementById('language-menu-dropdown-mobile-span3');
        const mobileMenuSub2 = document.getElementById('sign-in-menu-dropdown-mobile-span');
        const mobileMenuSub3 = document.getElementById('orders-menu-dropdown-mobile-span');
        const mobileMenuSub4 = document.getElementById('returns-menu-dropdown-mobile-span');

        //closes the menu if anything but the menu and its submenus is clicked. any new submenus and ids need to be added here so a click on them wont trigger the whole thing dissapearing
        if (!mobileMenu.contains(event.target) && event.target !== hamburgMenu && event.target !== hamburgSpan && event.target !== mobileMenuSub1 && event.target !== mobileMenuSub2 && event.target !== mobileMenuSub3 && event.target !== mobileMenuSub4 && event.target !== mobileMenuSub12 && event.target !== mobileMenuSub13) {
            mobileMenu.classList.add('hidden');
            subLan.classList.add('hidden');
            subSignin.classList.add('hidden');
            subOrders.classList.add('hidden');
            subReturns.classList.add('hidden');

        }

        //
        // add logic for shopping cart to close if clicked the cart screen
        //

        //close all other submenus when opening another submenu

        if (!mobileMenu.contains(event.target) && event.target !== hamburgMenu && event.target !== hamburgSpan) {
            mobileMenuSub1.classList.add('hidden');
            mobileMenuSub2.classList.add('hidden');
            mobileMenuSub3.classList.add('hidden');
            mobileMenuSub4.classList.add('hidden');

        }


    });

    function toggleMobileMenu() {
        const mobileMenu = document.getElementById('language-menu-mobile');
        mobileMenu.classList.toggle('hidden');
        if(subLan.classList.contains('hidden')){subLan.classList.add('hidden');}
        else{subLan.classList.toggle('hidden');}

        if(subSignin.classList.contains('hidden')){subSignin.classList.add('hidden');}
        else{subSignin.classList.toggle('hidden');}

        if(subOrders.classList.contains('hidden')){subOrders.classList.add('hidden');}
        else{subOrders.classList.toggle('hidden');}

        if(subReturns.classList.contains('hidden')){subReturns.classList.add('hidden');}
        else{subReturns.classList.toggle('hidden');}
        // subSignin.classList.toggle('hidden');
        // subOrders.classList.toggle('hidden');
        // subReturns.classList.toggle('hidden');
        mobileMenuVisible = !mobileMenuVisible;
    }



    function show(elementID) {//from   w w w . j  a  va2  s.  c o  m

        var show_menu = document.getElementById(elementID);
        if (currentlyOpenMenu != null)
            document.getElementById(currentlyOpenMenu).style.display ="none"; //close the previous menu, if exists
        currentlyOpenMenu = elementID;
        show_menu.style.display="block";
        clearTimeout(timer);


    }

    function hide(elementID) {
        var hide_menu = document.getElementById(elementID);
        timer = setTimeout(function() {
            hide_menu.style.display = "none";
        }, 70);
    }

    function toggle(elementID) {
        var element = document.getElementById(elementID);
        if (element.classList.contains("hidden")) {
            element.classList.remove("hidden");
        } else {
            element.classList.add("hidden");
        }
    }

    function close(elementID) {
        var element = document.getElementById(elementID);
        element.classList.add("hidden");
    }

    function toggleLangMobile(){
        toggle('language-menu-dropdown-mobile');
        close('sign-in-menu-dropdown-mobile');
        close('orders-menu-dropdown-mobile');
        close('returns-menu-dropdown-mobile');
    }

    function toggleSignInMobile(){
        close('language-menu-dropdown-mobile');
        toggle('sign-in-menu-dropdown-mobile');
        close('orders-menu-dropdown-mobile');
        close('returns-menu-dropdown-mobile');
    }

    function toggleOrdersMobile(){
        close('language-menu-dropdown-mobile');
        close('sign-in-menu-dropdown-mobile');
        toggle('orders-menu-dropdown-mobile');
        close('returns-menu-dropdown-mobile');
    }

    function toggleReturnsMobile(){
        close('language-menu-dropdown-mobile');
        close('sign-in-menu-dropdown-mobile');
        close('orders-menu-dropdown-mobile');
        toggle('returns-menu-dropdown-mobile');
    }
    function checkScreenSize() {
        if (window.innerWidth >= 1024) { // Tailwind CSS breakpoints: md and lg
            close('language-menu-mobile');
        }
    }


    window.addEventListener('resize', checkScreenSize);