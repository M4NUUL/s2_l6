#pragma once
#include <string>
#include <optional>

struct Person {
  long id{};
  std::string last, first;
  std::optional<std::string> middle;
  std::optional<std::string> birth_date; // можно строкой YYYY-MM-DD для простоты
};
#pragma once
#include <string>
#include <optional>

struct Person {
  long id{};
  std::string last;
  std::string first;
  std::optional<std::string> middle;
};
