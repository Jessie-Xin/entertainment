import {ScratchToReveal} from "@/components/magicui/scratch-to-reveal";

export default function Home() {
    return (
        <div className="flex h-full items-center justify-center">
            <ScratchToReveal
                width={350}
                height={350}
                minScratchPercentage={70}
                className="flex items-center justify-center overflow-hidden rounded-2xl border-2 bg-gray-100"
                gradientColors={["#A97CF8", "#F38CB8", "#FDCC92"]}
            >
                <p className="text-[9.375rem]">🤡</p>
            </ScratchToReveal>
        </div>
    );
}
