class Product {
    constructor(data, defaultImgSize) {
        this.top = data;
        this.maskVariants = data.maskVariants;
        this._current = null;
        this.defaultImgSize = defaultImgSize ? defaultImgSize : "";
        this.maskIdxByFType = {};
        const featureTypeById = this.featureTypeById;
        if(featureTypeById) {
            for(const fTypeId in featureTypeById) {
                this.maskIdxByFType[fTypeId] = 0;
            }
        }
        this.setSelected(this.top);
    }
    setSelected(selected) {
        if(!selected) selected = this.top;
        this.images = selected["images" + this.defaultImgSize];
        this.currentImage = this.images.length > 0 ? this.images[0] : null;
    }

    select(featureTypeId, fMaskIndex) {
        this.maskIdxByFType[featureTypeId] = fMaskIndex;
        let idx = 0;
        for(const fTypeId in this.maskIdxByFType) {
            idx += this.maskIdxByFType[fTypeId];
        }
        this.setSelected(this.maskVariants[idx]);
    }
    unselect(featureTypeId) {
        this.maskIdxByFType[featureTypeId] = 0;
    }

    get current() { return this._current; }
    set current(data) {
        this._current = data;
        this.images = this._current.images;
        this.currentImage = this.images.length > 0 ? this.images[0] : null;
        for(const featureId in this._current.featureById) {
            let feature = this.featureById[featureId];
            this.select(feature.productFeatureTypeEnumId, feature.maskIndex);
        }
    }
    get name() { return this.top.productName; }
    get description() { return this.top.description; }
    get listPrice() { return this.top.PppPurchasePptListPrice; }
    get price() { return this.top.PppPurchasePptCurrentPrice; }
    get comments() { return this.top.comments; }
    get featureIdsByType() {return this.top.featureIdsByType; }
    get featureById() {return this.top.featureById; }
    get featureTypeById() { return this.top.featureTypeById; }
}