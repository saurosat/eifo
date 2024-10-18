function getReqHeader(ua) {
    let headers = { "Content-Type": "application/json;charset=UTF-8", "store": storeId, "moquiSessionToken": ua.token ? ua.token : sessionToken, "SessionToken" : ua.token, "X-CSRF-Token": ua.token };
    if(ua.apiKey != null) {
        headers["api_key"] = ua.apiKey;
    }
    return headers;
}
function getReqCfg(method, ua) {
    return { headers: getReqHeader(ua), hostname: "localhost", port: "8080", protocol: "http:", method: method }
}

class Observable {
    constructor() {
        this.observers = [];
    }
    observe(observer) {
        if(!observer || (typeof observer != 'function' && (!observer.update || typeof observer.update != 'function'))) {
            console.log("Invalid observer");
            return;
        }
        if(this.observers.indexOf(observer) < 0) {
            this.observers.push(observer);
        }
    }
    unobserve(observer) {
        let i = this.observers.indexOf(observer);
        if(i < 0) return null;
        return this.observers.splice(i, 1);
    }
    notifyAll() {
        for(let i = 0; i < this.observers.length; i++) {
            let observer = this.observers[i];
            if(typeof observer == "function") {
                observer(this)
            } else {
                this.observers[i].update(this);
            }
        }
    }
}
class LazyList extends Observable {
    constructor(loader) {
        this.items = loader();
    }
}

class Executor extends Observable {
    constructor(callable) {
        super()
        this.callable = callable;
        this.isDone = false;
    }
    invoke() {
        if(this.callable) {
            this.callable();
        }
        this.isDone = true;
        this.notifyAll();
    }
    update() {
        this.invoke();
    }
}
class Closable extends Executor {
    constructor(dialog = null, button = null) {
        super()
        this.dialog = dialog;
        if(typeof button == "string") {
            this.buttonId = button;
            this.button = document.getElementById(this.buttonId);
        } else {
            this.button = button;
        }
        this.isOpen = false;
        this.isDone = false;
    }
    toggle() {
        return this.isOpen ? this.close() : this.invoke();
    }
    open() {
        this.isOpen = true;
        if(this.dialog) this.dialog.focus();
    }
    close() {
        this.isOpen = false;
        this.isDone = true;
        if(this.button) this.button.focus();
        this.notifyAll();
    }
}
class Dialog extends Closable {
    constructor(dialog = null, button = null) {
        super(dialog, button);
        this.isOpen = false;
        this.isLoading = false;
        this.isDone = false;
        this.isChanged = false;
    }
    close() {
        this.isOpen = false;
        if(this.button) this.button.focus();
        this.notifyAll();
    }
    invoke() {
        this.isOpen = false;
        this.isLoading = false;
        this.isChanged = this.isDone;
        if(this.button) this.button.focus();
        // this.isDone = true;
        // this.notifyAll();
        super.invoke();
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

class Wizard extends Executor {
    constructor() {
        super();
        this.viewIndex = 0;
        this.stepIndex = 0;
        /**
         * A map with key is the result code of previous step and value is the next step needed to be
         * done for that result
         */
        this.steps = [];
    }
    //currentStatus() {return this.statusCodes[this.statusCodes.length - 1]}
    update(closableDlg) {
        if(closableDlg.isOpen || !closableDlg.isDone || this.viewIndex == this.steps.length - 1) {
            return;
        }
        
        
        if(closableDlg.isChanged) {
            //Invalidate all dialogs behind
            for(let i = this.viewIndex + 1; i <= this.stepIndex; i++) {
                this.steps[i].isDone = false;
            }
            this.stepIndex = this.viewIndex; 
        }
        if(this.viewIndex <= this.stepIndex) {
            this.viewIndex++;
        }
        if(this.stepIndex < this.viewIndex) {
            this.stepIndex++;
        }
        this.steps[this.viewIndex].invoke();
    }
    next() {
        if(this.viewIndex < this.stepIndex){
            this.viewIndex++;
            this.invoke();
        } 
    }
    prev() {
        if(this.viewIndex > 0) {
            this.viewIndex--;
            this.invoke();
        }
    }
    invoke() {
        this.steps[this.viewIndex].invoke();
    }

    addStep(step) {
        let executor = (typeof step == "function") ? new Executor(step) : step;
        this.steps.push(executor);
        executor.attach(this)
    }
}
