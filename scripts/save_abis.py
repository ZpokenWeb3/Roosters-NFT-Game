import json
import os


def main():

    build_path = os.getcwd() + "/build/contracts"
    save_path = build_path + "/ABIs"

    if not os.path.exists(save_path):
        os.mkdir(save_path)

    for filename in os.listdir(build_path):
        if filename.endswith(".json"):
            print("Saving", filename)

            with open(os.path.join(build_path, filename), "r") as f:
                abi = json.load(f)

            with open(os.path.join(save_path, filename), "w", encoding="utf-8") as f:
                json.dump(abi["abi"], f, ensure_ascii=False, indent=4)


if __name__ == "__main__":
    main()
