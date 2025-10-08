#include <gpio_presence.hpp>

#include <set>

const constexpr char* inventoryPath = "/xyz/openbmc_project/inventory";
const constexpr char* intfName = "xyz.openbmc_project.Configuration.GPIO";

int main()
{
    boost::asio::io_context io;
    auto systemBus = std::make_shared<sdbusplus::asio::connection>(io);
    systemBus->request_name("xyz.openbmc_project.GpioPresence");
    sdbusplus::asio::object_server objectServer(systemBus, true);
    objectServer.add_manager("/xyz/openbmc_project/gpios");

    boost::container::flat_map<std::string, std::shared_ptr<gpioPresence>>
        gpios;
    std::vector<std::unique_ptr<sdbusplus::bus::match::match>> matches;

    std::set<std::string> handledPaths;

    std::function<void(sdbusplus::message::message&)> eventHandler =
        [&](sdbusplus::message::message& message) {
            std::string objectPath = message.get_path();

            if (handledPaths.find(objectPath) != handledPaths.end())
            {
                return; // Ignoring event for already processed object path
            }

            if (message.is_method_error())
            {
                std::cerr << "callback method error\n";
                return;
            }

            sdbusplus::message::message getGpioProperties =
                systemBus->new_method_call(
                    message.get_sender(), message.get_path(),
                    "org.freedesktop.DBus.Properties", "GetAll");
            getGpioProperties.append(intfName);
            boost::container::flat_map<
                std::string, std::variant<std::string, uint64_t, bool>>
                gpioProperties;
            try
            {
                sdbusplus::message::message getGpioPropertiesResp =
                    systemBus->call(getGpioProperties);
                getGpioPropertiesResp.read(gpioProperties);
            }
            catch (const sdbusplus::exception_t&)
            {
                std::cerr << "error getting gpio status from "
                          << message.get_path() << "\n";
                return;
            }
            auto getGpioName = gpioProperties.find("LineName");
            std::optional<std::string_view> lineName;

            if (getGpioName != gpioProperties.end())
            {
                lineName = std::get<std::string>(getGpioName->second);
                lineName->remove_prefix(std::min(
                    lineName->find_last_of(".") + 1, lineName->size()));
            }

            auto getName = gpioProperties.find("Name");
            std::optional<std::string_view> gpioName;

            if (getName != gpioProperties.end())
            {
                gpioName = std::get<std::string>(getName->second);
                gpioName->remove_prefix(std::min(
                    gpioName->find_last_of(".") + 1, gpioName->size()));
            }

            auto& gpioConstruct = gpios[gpioName->data()];
            gpioConstruct = nullptr;
            gpioConstruct = std::make_shared<gpioPresence>(
                objectServer, systemBus, io, gpioName->data(),
                lineName->data());

            handledPaths.insert(objectPath);
        };

    auto match = std::make_unique<sdbusplus::bus::match::match>(
        static_cast<sdbusplus::bus::bus&>(*systemBus),
        "type='signal',member='PropertiesChanged',path_namespace='" +
            std::string(inventoryPath) + "',arg0namespace='" +
            std::string(intfName) + "'",
        eventHandler);

    matches.emplace_back(std::move(match));

    io.run();

    return 0;
}
