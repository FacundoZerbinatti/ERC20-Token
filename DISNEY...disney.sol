// SPDX-License-Identifier: MIT
pragma solidity >=0.4.4 <0.7.0;
pragma experimental ABIEncoderV2;
import "./ERC20/ERC20.sol";

contract Disney {

    //-------------------------------- DECLARACIONES INICIALES --------------------------------

    // Instancia del contrato token
    ERC20Basic private token;

    // Direccion de Disney (owner)
    address payable public owner;

    // Constructor 
    constructor () public {
        token = new ERC20Basic(10000); // cantidad de monedas que se van a crear 10.000
        owner = msg.sender;            // msg.sender es el user que despliega el S.C
    }

    // Estructura de datos para almacenar los clientes de Disney
    struct cliente {
        uint tokens_comprados;
        string [] atracciones_disfrutadas;
    }

    //Mapping para el registro de clientes
    mapping (address => cliente) public Clientes;

    //-------------------------------- GESTION DE TOKENS --------------------------------

    // Funcion para establecer el precio de un Token
    function PrecioTokens(uint _numTokens) internal pure returns (uint) {
        // Conversion de Tokens a Ethers: 1Token -> 0.1 Ether
        return _numTokens*(0.1 ether);
    }

    // Funcion para comprar comprar Tokens en Disney
    function CompraTokens(uint _numTokens) public payable {
        // Establecer el precio de los Tokens
        uint coste = PrecioTokens(_numTokens);
        // Se evalua si el cliente tiene el dinero para comprar Tokens
        require (msg.value >= coste, "Compra menos Tokens o paga con mas ethers.");
        // Diferencia o vuelto de lo que el cliente paga
        uint returnValue = msg.value - coste;
        // Disney retorna la cantidad de ethers al cliente
        msg.sender.transfer(returnValue);
        // Obtencion del numero de tokens disponibles
        uint Balance = TotalBalance();
        require(_numTokens <= Balance, "Compra un numero menor de Tokens");
        // Se tranfiere el numero de tokens al cliente
        token.transfer(msg.sender, _numTokens);
        // Registro de tokens comprados
        Clientes[msg.sender].tokens_comprados += _numTokens;
    }

    // Balance de tokens del contrato disney
    function TotalBalance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    // Visualizar el numero de tokens restantes de un cliente
    function MisTokens() public view returns (uint) {
        return token.balanceOf(msg.sender);
    }

    // Function para generar mas tokens
    function GeneraTokens(uint _numTokens) public Unicamente(msg.sender){
        return token.increaseTotalSupply(_numTokens);
    }

    // Modificador para controlar las funciones ejecutables por disney
    modifier Unicamente(address _direccion) {
        require(_direccion == owner, "No tienes permisos para ejecutar esta funcion.");
        _;
    }

    //-------------------------------- GESTION DE DISNEY --------------------------------

    // Eventos
    event disfruta_atraccion(string, uint, address);       // evento para publicidad por ejemplo
    event alta_atraccion(string, uint);           
    event baja_atraccion(string);

    event compra_comida(string, uint, address);
    event alta_comida(string, uint);
    event baja_comida(string);

    // Estructura de datos de la atraccion
    struct atraccion {
        string nombre_atraccion;
        uint precio_atraccion;
        bool estado_atraccion;
    }

    // Estructura de datos de la comida
    struct comida {
        string nombre_comida;
        uint precio_comida;
        bool stock_comida;
    }

    // Mapping para relacion un nombre de una atraccion con una estructura de datos de la atraccion
    mapping (string => atraccion) public MappingAtracciones;
    // Array para almacenar el nombre de las atracciones;
    string [] Atracciones;
    // Mapping para relacionar un cliente con su historial en Disney
    mapping (address => string []) HistorialAtracciones;


    // Mapping para relacion de nombre de comida con una estructura de datos de la comida
    mapping (string => comida) public MappingComida;
    // Array para almacenar el nombre de las comidas;
    string [] Comidas;
    // Mapping para relacionar un cliente con su historial de comidas en Disney
    mapping (address => string []) HistorialComidas;


// ATRACCIONES:
    // Crear nuevas atracciones para Disney (SOLO es ejecutable por Disney)
    function AltaAtraccion(string memory _nombreAtraccion, uint _precio) public Unicamente (msg.sender) {
        // Creacion de una atraccion en Disney
        MappingAtracciones[_nombreAtraccion] = atraccion(_nombreAtraccion, _precio, true);
        // Almancenamiento en un array, el nombre de la atraccion
        Atracciones.push(_nombreAtraccion);
        // Emision del evento para la alta de la atraccion
        emit alta_atraccion(_nombreAtraccion, _precio);
    }
    // Dar de baja atracciones para Disney (SOLO es ejecutable por Disney)
    function BajaAtraccion(string memory _nombreAtraccion) public Unicamente (msg.sender) {
        // El estado de la atraccion pasa a FALSE -> no esta en uso
        MappingAtracciones[_nombreAtraccion].estado_atraccion = false;
        // Emision del evento para la baja de la atraccion
        emit baja_atraccion(_nombreAtraccion);
    }

    // Funcion para visualizar las atracciones de Disney
    function AtraccionesDisponibles() public view returns (string [] memory) {
        return Atracciones;
    }

    // Funcion para subirse una atraccion de Disney y pagar en tokens
    function SubirseAtraccion (string memory _nombreAtraccion) public {
        // Precio de la atraccion (en Tokens)
        uint tokens_atraccion = MappingAtracciones[_nombreAtraccion].precio_atraccion;
        // Verificar el estado de la atraccion (si esta disponible para su uso)
        require(MappingAtracciones[_nombreAtraccion].estado_atraccion == true,
                "La atraccion no esta disponible en estos momentos.");
        // Verificar el numero de tokens que tiene el cliente para subirse a la atraccion
        require(tokens_atraccion <= MisTokens(),
                "Necesitas mas Tokens para subierte a esta atraccion.");
        /*
            El cliente para la atraccion en Tokens:
            - Ha sido necesario crear una funcion en ERC20.sol con el nombre de: 'transferencia_disney' 
              debido a que en caso de usar el Transfer o TransferFrom las direcciones que se escogian
              para realizar la transaccion eran equivocadas. Ya que el msg.sender que recibia el metodo
              Transfer o TransferFrom era la direccion del contrato.
        */
        token.transferencia_disney(msg.sender,  address(this), tokens_atraccion);
        // Almacenamiento en el historial de atracciones del cliente
        HistorialAtracciones[msg.sender].push(_nombreAtraccion);
        // Emision del evento para disfrutar una atraccion
        emit disfruta_atraccion(_nombreAtraccion, tokens_atraccion, msg.sender);
    }

    // Consulta historial de atracciones disfrutadas por un cliente
    function ConsultaHistorial() public view returns (string [] memory) {
        return HistorialAtracciones[msg.sender];
    }

    // COMIDAS:
    // Crear nuevas comidas para Disney (SOLO es ejecutable por Disney)
    function AltaComida(string memory _nombreComida, uint _precio) public Unicamente (msg.sender) {
        // Creacion de una comida en Disney
        MappingComida[_nombreComida] = comida(_nombreComida, _precio, true);
        // Almancenamiento en un array, el nombre de la atraccion
        Comidas.push(_nombreComida);
        // Emision del evento para la alta de la atraccion
        emit alta_comida(_nombreComida, _precio);
    }

    // Dar de baja atracciones para Disney (SOLO es ejecutable por Disney)
    function BajaComida(string memory _nombreComida) public Unicamente (msg.sender) {
        // El estado de la atraccion pasa a FALSE -> no esta en uso
        MappingComida[_nombreComida].stock_comida = false;
        // Emision del evento para la baja de la atraccion
        emit baja_comida(_nombreComida);
    }

    // Funcion para visualizar las comidas de Disney
    function ComidasDisponibles() public view returns (string [] memory) {
        return Comidas;
    }

    // Funcion para comprar comida en Disney y pagar en tokens
    function ComprarComida (string memory _nombreComida) public {
        // Precio de la comida (en Tokens)
        uint tokens_comida = MappingComida[_nombreComida].precio_comida;
        // Verificar si hay stock de la comida (si esta disponible para su uso)
        require(MappingComida[_nombreComida].stock_comida == true,
                "La comida no esta disponible en estos momentos.");
        // Verificar el numero de tokens que tiene el cliente para comprar comida
        require(tokens_comida <= MisTokens(),
                "Necesitas mas Tokens para comprar esta comida.");
        /*
            El cliente para la atraccion en Tokens:
            - Ha sido necesario crear una funcion en ERC20.sol con el nombre de: 'transferencia_disney' 
              debido a que en caso de usar el Transfer o TransferFrom las direcciones que se escogian
              para realizar la transaccion eran equivocadas. Ya que el msg.sender que recibia el metodo
              Transfer o TransferFrom era la direccion del contrato.
        */
        token.transferencia_disney(msg.sender,  address(this), tokens_comida);
        // Almacenamiento en el historial de comidas del cliente
        HistorialComidas[msg.sender].push(_nombreComida);
        // Emision del evento para disfrutar una atraccion
        emit compra_comida(_nombreComida, tokens_comida, msg.sender);
    }

    // Consulta historial de atracciones disfrutadas por un cliente
    function ConsultaHistorialComidas() public view returns (string [] memory) {
        return HistorialComidas[msg.sender];
    }

    // Funcion que permite devolver los tokens sobrantes de un cliente
    function DevolverTokens (uint _numTokens) public payable {
        // Verificar que el numero de tokens a devolver es positivo
        require(_numTokens > 0, "Necesitas devolver una cantidad positiva de Tokens.");
        // El usuario debe tener el numero de Tokens que desea devolver
        require(_numTokens <= MisTokens(), "No tiene los Tokens que deseas devolver.");
        // El cliente devuelve los tokens
        token.transferencia_disney(msg.sender, address(this), _numTokens);
        // Devolucion de los ethers al cliente
        msg.sender.transfer(PrecioTokens(_numTokens));
    }
}