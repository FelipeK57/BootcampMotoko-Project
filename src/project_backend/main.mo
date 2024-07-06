import Text "mo:base/Text";
import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
import Types "Types";

//Canister principal - Delivery App
actor {
  //Variable users : HashMap - Key (Text) & Type (User)
  //(var users) -> HashMap where we save users
  var users = HashMap.HashMap<Text, Types.User>(5, Text.equal, Text.hash);

  //Variable dishes: HashMap - Key (Text) & Type (Dish)
  //(var dishes) -> HashMap where we save dishes
  var dishes = HashMap.HashMap<Text, Types.Dish>(5, Text.equal, Text.hash);

  //Variable shoppingCart: HashMap - Key (Text) & Type (Dish)
  //(var shoppingCart) -> HashMap where we save dishes in a shopping cart customer
  var shoppingCart = HashMap.HashMap<Text, Types.ShoppingCart>(5, Text.equal, Text.hash);

  //Variable orders : HashMap - Key (Text) & Type (Order)
  //(var orders) -> HashMap where we save orders of the customers
  var orders = HashMap.HashMap<Text, Types.Order>(5, Text.equal, Text.hash);

  //Variable orders : HashMap - Key (Text) & Type (Order)
  //(var orders) -> HashMap where we save orders of the customers
  var ordersDelivered = HashMap.HashMap<Text, Types.OrdersDelivered>(5, Text.equal, Text.hash);

  //Func registerUsers : update func - Parameters - id (Text), name (Text) & role (Role)
  //(public func registerUsers) -> Function where we register users and save in (var users)
  public func registerUsers(id : Text, name : Text, role : Types.Role) : async Text {
    let new_user = {
      id = id;
      name = name;
      role = role;
    };
    if (role == #customer) {
      let new_cart = {
        cartId = id # Nat.toText(1000);
        userId = id;
        dishes = "";
        totalPrice = 0;
      };
      shoppingCart.put(id, new_cart);
    };
    users.put(id, new_user);
    return "Successfully registered user";
  };

  //Func getUser : query func - Parameters - id (Text)
  //(public query func getUser) -> Function that return user in users (HashMap) if received a valid id
  public query func getUser(id : Text) : async ?Types.User {
    return users.get(id);
  };

  //Func createMenu : update func - Parameters - id (Text), name (Text) & price (Nat)
  //(public func createMenu) -> Function to create a menu for the restaurant linked with received valid id
  public func createMenu(restaurantId : Text, id : Text, name : Text, price : Nat) : async Text {
    if (users.get(restaurantId) != null) {
      let new_dish = {
        restaurantId = restaurantId;
        id = id;
        name = name;
        price = price;
      };
      dishes.put(id, new_dish);
      return "Succesfully registered dish";
    };
    return "Restaurant don't exists";
  };

  //Func getMenu : query func - Parameters : id (Text)
  //(public query func getMenu) -> Function that return menu (Text) of the restaurant if received a valid id
  public query func getMenu(id : Text) : async Text {
    var menu = "";
    for (value in dishes.vals()) {
      if (value.restaurantId == id) {
        menu := menu # "{ " # value.id # ", " # value.name # ", " # Nat.toText(value.price) # "$" # " }";
      };
    };
    return menu;
  };

  //Func addInCart : update fun - Parameters : userId (Text) & dishId (Text)
  //(public func addInCart) -> Function that adds a dish to the shopping cart if received a valid id
  public func addInCart(userId : Text, dishId : Text) : async Text {
    var user = users.get(userId);
    var dishOpt = dishes.get(dishId);
    if (user != null) {
      switch (dishOpt) {
        case (null) {
          return "Dish doesn't exist";
        };
        case (?dish) {
          var ncartId : Text = "";
          var nuserId : Text = "";
          var ndishes : Text = "";
          var ntotalPrice : Nat = 0;
          for (value in shoppingCart.vals()) {
            if (value.userId == userId) {
              ncartId := ncartId # value.cartId;
              nuserId := nuserId # value.userId;
              ndishes := ndishes # value.dishes # "{ " # dish.id # ", " # dish.name # ", " # Nat.toText(dish.price) # "$" # " }";
              ntotalPrice := value.totalPrice + dish.price;
            };
          };
          var update_cart = {
            cartId = ncartId;
            userId = nuserId;
            dishes = ndishes;
            totalPrice = ntotalPrice;
          };
          shoppingCart.put(userId, update_cart);
          return "Added successfully to the shopping cart";
        };
      };
    };
    return "User doesn't exist";
  };

  //Func lookShoppingCart : query func - Parameters : id (Text)
  //(public query func lookShoppingCart) -> Function that returns the shopping cart (Text) of the customer if a valid id is received
  public query func lookShoppingCart(id : Text) : async Text {
    var cart = "";
    for (value in shoppingCart.vals()) {
      if (value.userId == id) {
        cart := cart # value.dishes # " - total price = " # Nat.toText(value.totalPrice) # "$";
      };
    };
    return cart;
  };

  //Func cleanShoppingCart : update func - Parameters : id (Text)
  //(public func cleanShoppingCart) -> Function that clean shopping cart of the user if a valid id is received
  public func cleanShoppingCart(id : Text) : async Text {
    var userCart = shoppingCart.get(id);
    if (userCart != null) {
      let empty_cart = {
        cartId = id # Nat.toText(1000);
        userId = id;
        dishes = "";
        totalPrice = 0;
      };
      shoppingCart.put(id, empty_cart);
      return "Shopping cart successfully emptied";
    };
    return "User doesn't exist";
  };

  //Func makeOrder : update func - Parameters : id (Text) & address (Text)
  //(public func makeOrder) -> Function that make order of the user if a valid id is received
  public func makeOrder(id : Text, address : Text) : async Text {
    var userOrder = users.get(id);
    var userCart = shoppingCart.get(id);
    if (userOrder != null) {
      switch (userCart) {
        case (?cart) {
          if (cart.totalPrice != 0) {
            let new_order : Types.Order = {
              orderId = id # Nat.toText(1000);
              user = id;
              dishes = ?cart;
              address = address;
              status = ? #preparing;
              deliveryPerson = null;
            };
            orders.put(id, new_order);
            return "Order sent successfully";
          };
          return "The shopping cart is empty";
        };
        case (null) {
          return "Cart doesn't exist";
        };
      };
    };
    return "User doesn't exist";
  };

  //Func getOrders : query func - Parameter : id (Text)
  //(public query func getOrders) -> Function that return orders if status order is "preparing" and if a valid delivery person id is received
  public query func getOrders(id : Text) : async Text {
    var deliveryPerson = users.get(id);
    switch (deliveryPerson) {
      case (?deliveryP) {
        if (deliveryP.role == #deliveryPerson) {
          var ordersText = "";
          for (order in orders.vals()) {
            switch (order.dishes) {
              case (?cart) {
                if (order.status == ? #preparing) {
                  let orderDetails = "{ " # order.user # ", " # cart.dishes # ", " # order.address # ", " # Nat.toText(cart.totalPrice) # "$" # " }";
                  ordersText := ordersText # orderDetails;
                };
              };
              case (null) {

              };
            };
          };
          if (ordersText != "") {
            return ordersText;
          } else {
            return "No orders are currently preparing.";
          };
        } else {
          return "You are not a delivery person";
        };
      };
      case (null) {
        return "User doesn't exist";
      };
    };
  };

  //Func update selectOrder - Parameter : deliveryPersonId (Text) & orderId (Text)
  //(public func selectOrder) -> Function that changes status order "on the way" selected by delivery person if a valid id is received
  public func selectOrder(deliveryPersonId : Text, orderId : Text) : async Text {
    var deliveryPerson = users.get(deliveryPersonId);
    var order = orders.get(orderId);
    switch (deliveryPerson) {
      case (?deliveryP) {
        if (deliveryP.role == #deliveryPerson) {
          switch (order) {
            case (?orderSelected) {
              if (orderSelected.status == ? #preparing) {
                let updatedOrder : Types.Order = {
                  orderId = orderSelected.orderId;
                  user = orderSelected.user;
                  dishes = orderSelected.dishes;
                  address = orderSelected.address;
                  status = ? #onTheWay;
                  deliveryPerson = ?deliveryP;
                };
                orders.put(orderSelected.user, updatedOrder);
                return "Order selected successfully";
              } else {
                return "Order is not in 'preparing' status";
              };
            };
            case (null) {
              return "Order doesn't exist";
            };
          };
        } else {
          return "You are not a delivery person";
        };
      };
      case (null) {
        return "User doesn't exist";
      };
    };
  };

  //Func update orderDelivered - Parameter : deliveryPersonId (Text), orderId (Text) & deliveryTime (Text)
  //(public func orderDelivered) -> Function that confirms delivery and changes status order "delivered" if a valid id are received
  public func orderDelivered(deliveryPersonId : Text, orderId : Text, deliveryTime : Text) : async Text {
    var deliveryPerson = users.get(deliveryPersonId);
    var order = orders.get(orderId);
    if (deliveryPerson != null) {
      switch (order) {
        case (?orderSelected) {
          let update_order : Types.Order = {
            orderId = orderSelected.orderId;
            user = orderSelected.user;
            dishes = orderSelected.dishes;
            address = orderSelected.address;
            status = ? #delivered;
            deliveryPerson = deliveryPerson;
          };
          orders.delete(orderSelected.orderId);
          var id : Nat = ordersDelivered.size() + 1;
          let delivered_order : Types.OrdersDelivered = {
            id = Nat.toText(id);
            deliveryPerson = deliveryPersonId;
            order = ?update_order;
            date = deliveryTime;
          };
          ordersDelivered.put(Nat.toText(id), delivered_order);
          return "Order delivered successfully";
        };
        case (null) {

        };
      };
    };
    return "User doesn't exist";
  };

  //Func query getOrdersDelivered - Parameters : deliveryPersonId (Text)
  //(public query func getOrdersDelivered) -> Function that get all orders delivered of the delivery person if a valid id is received
  public query func getOrdersDelivered(deliveryPersonId : Text) : async Text {
    var ordersDeliveredByDP = "";
    for (value in ordersDelivered.vals()) {
      switch (value.order) {
        case (?order) {
          if (value.deliveryPerson == deliveryPersonId) {
            ordersDeliveredByDP := ordersDeliveredByDP # "{ " # value.date # ", " # order.user # ", " # order.address # " }";
          };
        };
        case (null) {

        };
      };
    };
    return ordersDeliveredByDP;
  };
};