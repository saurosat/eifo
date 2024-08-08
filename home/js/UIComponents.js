class Closable {
    constructor(dialog = null, button = null) {
        this.dialog = dialog;
        this.button = button;
        this.open = false;
    }
    toggle() {
        return this.open ? this.close() : this.open();
    }
    open() {
        this.open = true;
        if(this.dialog) this.dialog.focus();
    }
    close() {
        this.open = false;
        if(this.button) this.button.focus();
    }
    getResultCode() {
        return 0;
    }
}
class Cart extends Closable {
    constructor(dialog = null, button = null) {
        super(dialog, button);
        this.cartStore = Alpine.store('cartInfo');
        this.userStore = Alpine.store('user');
    }
    addProduct(product, quantity = 1) {
        let orderItems = this.cartStore.orderItemList;
        if(userStore.loggedIn) {
            ProductService.addProductCart(product, getReqConfig("post"))
                    .then(function (data) {
                        this.cartStore.reset();
                        this.cartStore.assign(data);
                    });
        } else {
            orderItems[orderItems.length] = {...product, quantity: quantity, currencyUomId: currencyUomId, productStoreId: storeId};
        }
        alert("Added product " + product.pseudoId);
    }
}
class Carousel {
    constructor(container, singleItem = false, timeout = 0) {
        this.current = 0;
        this.length = 0;
        this.singleItem = singleItem;
        this.timeout = timeout;
        this.container = container;
    }
    recalculate() {
        let children = this.container.children;
        this.length = children.length;
        if(!this.singleItem) {
            let leftOffsets = [];
            this.containerStyle = getComputedStyle(this.container)
            let x = 0;
            for(let i = 0; i < children.length; i++) {
                leftOffsets[i] = x;
                x += children[i].offsetWidth;
            }
            this.lastOffset = x;
            this.leftOffsets = leftOffsets;
        } 
    }
    next() {
        if(this.length === 0) {
            this.recalculate();
        }
        if(this.singleItem) {
            this.current++;
            if (this.current === this.length) this.current = 0;
            this.container.style.transform = "translateX(" + (-100*this.current) + "%)"
        } else {
            if(!this.offset) {
                this.offset = this.leftOffsets[this.current];
            }
            let rect = this.container.getBoundingClientRect();
            let maxOffset = this.lastOffset - rect.width;
            if(this.offset >= maxOffset) {
                this.offset = 0;
                this.current = 0;
            } else {
                this.offset += rect.width;
                let reachingTail = (this.offset > maxOffset);
                if(reachingTail) { // just gt, not gteq
                    this.offset = maxOffset;
                } 
                //search current by offset:
                for(; this.current < this.leftOffsets.length; this.current++) {
                    let curOffset = this.leftOffsets[this.current]
                    if(curOffset > this.offset) {
                        this.current --;
                        break;
                    } else if(curOffset == this.offset) {
                        break;
                    }
                    
                }
                if(!reachingTail) {
                    this.offset = this.leftOffsets[this.current]
                }
            }
            this.container.style.transform = "translateX(-" + this.offset + "px)"
        }
    }
    prev() {
        if(this.length === 0) {
            this.recalculate();
        }
        if(this.singleItem) {
            this.current--;
            if (this.current === -1) this.current = this.length - 1; 
            this.container.style.transform = "translateX(" + (-100*this.current) + "%)"
        } else {
            if(!this.offset) {
                this.offset = this.leftOffsets[this.current + 1];
            }

            let rect = this.container.getBoundingClientRect();
            let maxOffset = this.lastOffset - rect.width;
            if(this.offset == 0 || this.current == 0) {
                this.offset = maxOffset;
                for(this.current = this.length; this.current >= 0 && this.leftOffsets[this.current] > this.offset; this.current--);
            } else {
                this.offset -= rect.width;
                if(this.offset < 0) { // just gt, not gteq
                    this.offset = 0;
                    this.current = 0;
                } else {
                    for(; this.current > 0 && this.leftOffsets[this.current] > this.offset; this.current--);
                }
            }
            this.container.style.transform = "translateX(-" + this.offset + "px)"
        }
    }

}

class Wizard {
    constructor() {
        
        /** 
         * Result values the previous steps. Whenever a step done, its container html must be closed
         * and an integer value should be append to this proderty
         **/
        this.resultCodes = [0]; 

        /**
         * A map with key is the result code of previous step and value is the next step needed to be
         * done for that result
         */
        this.steps = [];
    }
    next() {
        let results = this.resultCodes;
        let nextStep = this.steps[results[results.length - 1]];
        if(nextStep) {
            nextStep.open();
        }
    }
    addStep(closableDlg, resultCode) {
        let self = this;
        closableDlg.__super_close = closableDlg.close;
        closableDlg.close = function() {
            closableDlg.__super_close();
            self.resultCodes[self.resultCodes.length] = closableDlg.getResultCode();
            self.next();
        };
        this.steps[resultCode] = closableDlg;
    }
}
