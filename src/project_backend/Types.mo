import Text "mo:base/Text";
import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
module {

    public type Role = {
        #customer;
        #restaurant;
        #deliveryPerson;
    };

    public type User = {
        id : Text;
        name : Text;
        role : Role;
    };

    public type Dish = {
        restaurantId : Text;
        id : Text;
        name : Text;
        price : Nat;
    };

    public type OrderStatus = {
        #preparing;
        #onTheWay;
        #delivered;
    };

    public type ShoppingCart = {
        cartId : Text;
        userId : Text;
        dishes : Text;
        totalPrice : Nat;
    };

    public type Order = {
        orderId : Text;
        user : Text;
        dishes : ?ShoppingCart;
        address : Text;
        status : ?OrderStatus;
        deliveryPerson : ?User;
    };

    public type OrdersDelivered = {
        id : Text;
        deliveryPerson : Text;
        order : ?Order;
        date : Text;
    };
};
